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


date=`date +%Y.%m.%d`
email="user@domain.net"
blocklog="/var/log/iptables.log"
log="/usr/local/admin/fwlog/$date-fwlog.log"


echo "fw.host.net iptables log analysis  -  $date" > $log
echo "" >> $log

grep SRC /var/log/iptables.log  |sed -e 's/.*SRC=//' -e 's/\ DST.*DPT=/|/' -e s'/\ .*//' >> $log.tmp
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


/sbin/iptables -L -v >> $log
echo "" >> $log
/sbin/iptables -L -v -t nat >> $log


cat $log |mail -s "fw.host.net iptable log analysis  -  $date" $email


rm  $log.tmp
find /usr/local/admin/fwlog/ -type f -name '*-fwlog.log' -mtime -30 -exec rm {} \;
