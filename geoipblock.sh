#!/bin/sh
#

# set variables
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
systemctl="/usr/bin/systemctl"
iptables="/sbin/iptables"
ipset="/sbin/ipset"
lan="enp1s0"


# download and unpack geoip data
wget -O /usr/local/admin/geoip/countries/all-zones.tar.gz http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz > /dev/null 2>&1
if [ $? = "0" ]; then
        cd /usr/local/admin/geoip/countries > /dev/null 2>&1
        rm -f /usr/local/admin/geoip/countries/*.zone
        tar zxvf all-zones.tar.gz > /dev/null 2>&1
        rm all-zones.tar.gz
        cd - > /dev/null 2>&1
fi


# delete geoip ipset list if exists
$iptables -D INPUT -i $lan -m set ! --match-set geoip src -j DROP > /dev/null 2>&1
$iptables -D INPUT -i $lan -m limit  --limit 1/s -m set ! --match-set geoip src -j LOG --log-prefix "geoblock: " > /dev/null 2>&1
$ipset destroy geoip > /dev/null 2>&1


# create geoip ipset list
$ipset create geoip hash:net


# populate geoip ipset list
for country in il us; do
        for ip in $( cat /usr/local/admin/geoip/countries/$country.zone ); do
                $ipset add geoip $ip
        done
done


# flush chains and set policies
$iptables -F
$iptables -P INPUT DROP
$iptables -P FORWARD DROP
$iptables -P OUTPUT DROP


# allow all packets on the loopback interface
$iptables -A INPUT -i lo -j ACCEPT
$iptables -A OUTPUT -o lo -j ACCEPT


# allow all traffic from local networks
$iptables -A INPUT -i $lan -s 192.168.0.0/24 -j ACCEPT
$iptables -A INPUT -i $lan -s 169.254.0.0/16 -j ACCEPT
$iptables -A INPUT -i $lan -s 127.0.0.0/8 -j ACCEPT


# allow multicase and broadcast traffic
$iptables -A INPUT -i $lan -m pkttype --pkt-type multicast -j ACCEPT
$iptables -A INPUT -i $lan -m pkttype --pkt-type broadcast -j ACCEPT


# allow established / related traffic
$iptables -A INPUT -i $lan -m state --state ESTABLISHED,RELATED -j ACCEPT
$iptables -A OUTPUT -o $lan -m state --state NEW -j ACCEPT
$iptables -A OUTPUT -o $lan -m state --state ESTABLISHED,RELATED -j ACCEPT


# drop traffic from countries other than IL and US
$iptables -A INPUT -i $lan -m limit  --limit 1/s -m set ! --match-set geoip src -j LOG --log-prefix "geoblock: "
$iptables -A INPUT -i $lan -m set ! --match-set geoip src -j DROP


# allow ssh traffic in
$iptables -A INPUT -i $lan -p tcp --dport 22 -j ACCEPT


# allow dhcp traffic in
$iptables -A INPUT -i $lan -p udp --dport 67:68 --sport 67:68 -j ACCEPT


# log all packets
$iptables -A INPUT -i $lan -p tcp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix "iptables: "
$iptables -A INPUT -i $lan -p udp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix "iptables: "


# drop all packets
$iptables -A INPUT -i $lan -p tcp --dport 0:65535 -j DROP
$iptables -A INPUT -i $lan -p udp --dport 0:65535 -j DROP


# restart fail2ban
$systemctl restart fail2ban
