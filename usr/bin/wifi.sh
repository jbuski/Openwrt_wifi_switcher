#!/bin/sh
mqtt_server="192.168.1.1"
mqtt_login="mqtt"
mqtt_pass="mqtt"
mqtt_topic="$(cat /proc/sys/kernel/hostname)"



while true; do
mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -t openwrt/$mqtt_topic/wifi/availability  -m "online"

opkgInstalled="$(opkg list-installed 2> /dev/null | wc -l)" #silencing error output
opkgUpgradable="$(opkg list-upgradable 2> /dev/null | wc -l)" #silencing error output
openwrtVersion="$(echo "$(awk -F= '$1=="DISTRIB_RELEASE" { print $2 ;}' /etc/openwrt_release)" | sed "s/'/\"/g")"

openwrtUptime="$(awk '{print int($1/86400)" days "int($1%86400/3600)":"int(($1%3600)/60)":"int($1%60)}' /proc/uptime)"

mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -t openwrt/$mqtt_topic/firmware -r -m "{\"installed\":$opkgInstalled, \"upgradable\" :$opkgUpgradable, \"version\" :$openwrtVersion}"

mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -t openwrt/$mqtt_topic/uptime -r -m "{\"uptime\":$openwrtUptime}"


if ! ping -q -c 5 -W 1 8.8.8.8 >/dev/null; then
	mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -t openwrt/$mqtt_topic/wifi/status -m '{"state":"DOWN"}'
	if ifconfig | grep wlan >/dev/null; then
	wifi down
	logger wifi down
	fi
else
	mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -t openwrt/$mqtt_topic/wifi/status -m '{"state":"UP"}'
	if ! ifconfig | grep wlan >/dev/null; then
	wifi up
	logger wifi up
	fi
fi
sleep 60
done