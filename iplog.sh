#!/bin/sh
#
# iptables firewall log analysis
#

if [ $EUID != "0" ]; then
        echo ""
        echo "$0 needs to be ran by root.  re-executing with sudo"
        echo ""
        exec sudo /bin/bash "$0" "$@"
fi


blocklog="/var/log/iptables.log"
log="/usr/local/admin/fwlog/iplog.log"


grep SRC /var/log/iptables.log  |sed -e 's/.*SRC=//' -e 's/\ DST.*DPT=/|/' -e s'/\ .*//' > $log.tmp
printf "%-32s %-20s %-5s\n" "country" "ip" "port" >> $log
echo "-------------------------------------------------------------------------" >> $log

while IFS=$'|' read -r -a entry
do
        ip=${entry[0]}
        port=${entry[1]}
        country=`geoiplookup $ip|sed 's/GeoIP Country Edition://'`

        printf "%-32s %-20s %-5s\n" "$country" "$ip" "$port" >> $log
done < $log.tmp


echo "" >> $log
echo "" >> $log


/sbin/iptables -vnL --line-numbers >> $log
echo "" >> $log
/sbin/iptables -vnL -t nat >> $log


cat $log
rm $log
