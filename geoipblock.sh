#!/bin/sh
#
# download and unpack geoip data
wget -O /usr/local/admin/geoblock/countries/all-zones.tar.gz http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
if [ $? = "0" ]; then
        cd /usr/local/admin/geoblock/countries
        rm -f /usr/local/admin/geoblock/countries/*.zone
        tar zxvf all-zones.tar.gz
        rm all-zones.tar.gz
        cd -
fi


# delete iptables geoblock rule if exists
rule=$( iptables -vnL --line-numbers |grep geoblock |awk '{print $1}' )
if [ -n $rule ]; then
        iptables -D INPUT $rule
fi


# delete geoblock ipset list if exists
ipset list geoblock
if [ $? = "0" ]; then
        ipset destroy geoblock
fi


# create geoblock ipset list
ipset create geoblock hash:net


# populate geoblock ipset list
for country in br cn kp; do
        for ip in $( cat /usr/local/admin/geoblock/countries/$country.zone ); do
                ipset -A geoblock $ip
        done
done


# add iptables geoblock rule
iptables -I INPUT -m set --match-set geoblock src -j DROP
