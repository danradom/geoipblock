#!/bin/sh
#
# iptables firewall log analysis
#

if [ "$EUID" != "0" ]; then
        echo ""
        echo "$0 needs to be ran by root.  re-executing with sudo"
        echo ""
        exec sudo /bin/bash "$0" "$@"
fi


blocklog="/var/log/iptables.log"
log="/usr/local/admin/backup/iplog.log"


if [ -n "$1" ]; then
	grep geoblock /var/log/iptables.log |sed -e 's/.*SRC=//' -e 's/\ DST.*DPT=/|/' -e 's/\ .*//' |tail -$1 > $log.tmp
else
	grep geoblock /var/log/iptables.log |sed -e 's/.*SRC=//' -e 's/\ DST.*DPT=/|/' -e 's/\ .*//' > $log.tm
p
fi
printf "%-32s %-20s %-5s\n" "country" "ip" "port" >> $log
echo "-------------------------------------------------------------------------" >> $log

while IFS=$'|' read -r -a entry
do
        ip=${entry[0]}
        port=${entry[1]}
        country=`geoiplookup $ip|sed 's/GeoIP Country Edition://'`

        printf "%-32s %-20s %-5s\n" "$country" "$ip" "$port" >> $log
done < $log.tmp


cat $log
rm $log
