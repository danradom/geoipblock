# download and unpack geoip data
wget -O /usr/local/admin/geoblock/countries/all-zones.tar.gz http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz > /dev/null 2>&1
if [ $? = "0" ]; then
        cd /usr/local/admin/geoblock/countries > /dev/null 2>&1
        rm -f /usr/local/admin/geoblock/countries/*.zone
        tar zxvf all-zones.tar.gz > /dev/null 2>&1
        rm all-zones.tar.gz
        cd - > /dev/null 2>&1
fi


# delete iptables geoblock rule if exists
rule=$( iptables -vnL --line-numbers |grep geoblock |awk '{print $1}' )
if [ -n $rule ]; then
        iptables -D INPUT $rule
fi


# delete geoblock ipset list if exists
ipset list geoblock > /dev/null 2>&1
if [ $? = "0" ]; then
        ipset destroy geoblock
fi


# create geoblock ipset list
ipset create geoblock hash:net


# populate geoblock ipset list
echo ""
echo "generating list of IPs to block.  this may take a while"
echo ""
for country in br cn kp; do
        for ip in $( cat /usr/local/admin/geoblock/countries/$country.zone ); do
                ipset -A geoblock $ip
        done
done


# add iptables geoblock rule
iptables -I INPUT -m set --match-set geoblock src -j DROP


# display iptables rules
iptables -vnL --line-number
