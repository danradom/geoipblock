#!/bin/sh
#

# set variables
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
systemctl="/usr/bin/systemctl"
iptables="/sbin/iptables"
ipset="/sbin/ipset"
lan="enp1s0"


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


# allow multicast and broadcast traffic
$iptables -A INPUT -i $lan -m pkttype --pkt-type multicast -j ACCEPT
$iptables -A INPUT -i $lan -m pkttype --pkt-type broadcast -j ACCEPT


# allow established / related traffic
$iptables -A INPUT -i $lan -m state --state ESTABLISHED,RELATED -j ACCEPT
$iptables -A OUTPUT -o $lan -m state --state NEW -j ACCEPT
$iptables -A OUTPUT -o $lan -m state --state ESTABLISHED,RELATED -j ACCEPT


# recreate geoip ipset if needed
if [ "$1" = "geoip" ]; then
        $ipset destroy geoip > /dev/null 2>&1
        $ipset create geoip hash:net


        # populate geoip ipset list
        for ip in $( wget -qO- http://www.ipdeny.com/ipblocks/data/countries/il.zone http://www.ipdeny.com/ipblocks/data/countries/us.zone ); do
                $ipset add geoip $ip
        done
fi


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
