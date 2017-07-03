# download and unpack geoip data
wget -O /usr/local/admin/geoblock/countries/all-zones.tar.gz http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz > /dev/null 2>&1
if [ $? = "0" ]; then
        cd /usr/local/admin/geoblock/countries > /dev/null 2>&1
        rm -f /usr/local/admin/geoblock/countries/*.zone
        tar zxvf all-zones.tar.gz > /dev/null 2>&1
        rm all-zones.tar.gz
        cd - > /dev/null 2>&1
fi


# delete iptables geoblock rules
iptables -D INPUT -m set --match-set geoblock src -j DROP
iptables -D FORWARD -m set --match-set geoblock src -j DROP


# delete geoblock ipset list if exists
ipset list geoblock > /dev/null 2>&1
if [ $? = "0" ]; then
        ipset destroy geoblock
fi


# create geoblock ipset list
ipset create geoblock hash:net


# populate geoblock ipset list
echo ""
echo "generating list of IPs to allow.  this may take a while"
echo ""
# populate geoip ipset list
# must add local networks and such
ipset -A geoip 192.168.0.0/24
ipset -A geoip 192.168.1.0/24
ipset -A geoip 169.254.0.0/16
ipset -A geoip 224.0.0.0/4
for country in il us; do
        for ip in $( cat /usr/local/admin/geoip/countries/$country.zone ); do
                $ipset -A geoip $ip
        done
done


# add iptables geoblock rules
iptables -I INPUT -m set ! --match-set geoblock src -j DROP
iptables -I FORWARD -m set ! --match-set geoblock src -j DROP


# display iptables rules
iptables -vnL --line-number
