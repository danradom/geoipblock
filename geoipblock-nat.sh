#!/bin/sh
#
#

# set variables
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
systemctl="/usr/bin/systemctl"
iptables="iptables"
ipset="/sbin/ipset"
wan="enp1s0"
lan="enp2s0"


# adjust /proc settings
if [ -e /proc/sys/net/ipv4/tcp_syncookies ]; then echo 1 > /proc/sys/net/ipv4/tcp_syncookies; fi
if [ -e /proc/sys/net/ipv4/conf/all/rp_filter ]; then echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter; fi
if [ -e /proc/sys/net/ipv4/ip_forward ]; then echo 1 > /proc/sys/net/ipv4/ip_forward; fi


# flush any existing chains and set default policies
$iptables -F
$iptables -P INPUT DROP
$iptables -P OUTPUT DROP


# setup nat
$iptables -F -t nat
$iptables -P FORWARD DROP
$iptables -A FORWARD -i $lan -j ACCEPT
$iptables -A INPUT -i $lan -j ACCEPT
$iptables -A OUTPUT -o $lan -j ACCEPT
$iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o $wan -j MASQUERADE
$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT


# allow all packets on the loopback interface
$iptables -A INPUT -i lo -j ACCEPT
$iptables -A OUTPUT -o lo -j ACCEPT


# allow established and related packets back in
$iptables -A OUTPUT -o $wan -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$iptables -A INPUT -i $wan -m state --state ESTABLISHED,RELATED -j ACCEPT


# recreate geoip ipset list
if [ "$1" = "geoip" ]; then
        $ipset destroy geoip
        $ipset create geoip hash:net


        # populate geoip ipset list
        for ip in $( wget -qO- http://www.ipdeny.com/ipblocks/data/countries/il.zone http://www.ipdeny.com/ipblocks/data/countries/us.zone ); do
        # for ip in $( wget -qO- http://www.ipdeny.com/ipblocks/data/countries/il.zone ); do
                $ipset add geoip $ip
        done
fi


# blocking reserved private networks incoming from the internet
$iptables -I INPUT -i $wan -s 10.0.0.0/8 -j DROP
$iptables -I INPUT -i $wan -s 172.16.0.0/12 -j DROP
$iptables -I INPUT -i $wan -s 192.168.0.0/16 -j DROP
$iptables -I INPUT -i $wan -s 127.0.0.0/8 -j DROP
$iptables -I FORWARD -i $wan -s 10.0.0.0/8 -j DROP
$iptables -I FORWARD -i $wan -s 172.16.0.0/12 -j DROP
$iptables -I FORWARD -i $wan -s 192.168.0.0/16 -j DROP
$iptables -I FORWARD -i $wan -s 127.0.0.0/8 -j DROP


# icmp
# $iptables -A OUTPUT -p icmp -m state --state NEW -j ACCEPT
# $iptables -A INPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
# $iptables -A INPUT -p icmp --icmp-type echo-request -i $wan -j DROP
# $iptables -I INPUT -p icmp --icmp-type redirect -j DROP
# $iptables -I INPUT -p icmp --icmp-type router-advertisement -j DROP
# $iptables -I INPUT -p icmp --icmp-type router-solicitation -j DROP
# $iptables -I INPUT -p icmp --icmp-type address-mask-request -j DROP
# $iptables -I INPUT -p icmp --icmp-type address-mask-reply -j DROP


# drop traffic from countries other than IL and US
$iptables -A INPUT -i $wan -m limit  --limit 1/s -m set ! --match-set geoip src -j LOG --log-prefix "geoblock: "
$iptables -A FORWARD -i $wan -m limit  --limit 1/s -m set ! --match-set geoip src -j LOG --log-prefix "geoblock: "
$iptables -A INPUT -i $wan -m set ! --match-set geoip src -j DROP
$iptables -A FORWARD -i $wan -m set ! --match-set geoip src -j DROP


# open and forward ports to the internal machine(s)
$iptables -A FORWARD -i $wan -d 192.168.0.1 -p tcp --dport 22 -j ACCEPT
$iptables -A PREROUTING -t nat -i $wan -p tcp --dport 222 -j DNAT --to-destination 192.168.0.1:22


# logging
$iptables -A INPUT -i $wan -p tcp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix "iptables: "
$iptables -A INPUT -i $wan -p udp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix "iptables: "


# drop all other packets
$iptables -A INPUT -i $wan -p tcp --dport 0:65535 -j DROP
$iptables -A INPUT -i $wan -p udp --dport 0:65535 -j DROP
