# geoipblock
iptables / ipset GeoIP block script

- shell script that only allows traffic from specified countries
- generates new ipset when called with "geoip" $1 argument
- all packets pass through the geoipblock first
- nat and no nat versions
- support for fail2ban
- geoip and iptables log parsing scripts
