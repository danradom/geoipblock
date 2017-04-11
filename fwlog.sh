#!/bin/sh
#
# iptables firewall log analysis / geoip lookup
#

if [ $EUID != "0" ]; then
        echo ""
        echo "$0 needs to be ran by root.  re-executing with sudo"
        echo ""
        exec sudo /bin/bash "$0" "$@"
fi


date=`date +%Y.%m.%d`
email="user@domain.net"
blocklog="/var/log/iptables.log"
log="/usr/local/admin/fwlog/$date-fwlog.log"


echo "fw.domain.org iptables log analysis  -  $date" > $log
echo "" >> $log

grep SRC /var/log/iptables.log  |sed -e 's/.*SRC=//' -e 's/\ DST.*DPT=/|/' -e s'/\ .*//' >> $log.tmp
while IFS=$'|' read -r -a entry
do
        ip=${entry[0]}
        port=${entry[1]}

        echo -e "$ip:`geoiplookup $ip|sed 's/GeoIP Country Edition://'`\t\tport:$port" >> $log

done < $log.tmp


cat $log |mail -s "fw.radom.org iptable log analysis  -  $date" $email


rm  $log.tmp
find /usr/local/admin/fwlog/ -type f -name '*-fwlog.log' -mtime -30 -exec rm {} \;
