#!/bin/sh
#
# update geoip data
#

if [ "$EUID" != "0" ]; then
	echo ""
	echo "$0 needs to be ran by root.  re-executing with sudo"
	echo ""
	exec sudo /bin/bash "$0" "$@"
fi

date=`date +%Y.%m.%d.%H.%M`

wget -O /usr/share/GeoIP/GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz

mv /usr/share/GeoIP/GeoIP.dat /usr/share/GeoIP/GeoIP.dat-$date
gzip -d /usr/share/GeoIP/GeoIP.dat.gz
