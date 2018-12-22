---

classes:
  - network
  - ntp
  - profile::base

dhcp::failover:role:         'primary'
dhcp::failover:peer_address: '10.1.1.20'


dhcp::dnsdomain:
  - 'theclarkhome.com'
  - '11.168.192.in-addr.arpa'
dhcp::nameservers:
  - '10.1.1.10'
dhcp::interfaces:
  - 'eth0'

dhcp::pool:
  'theclarkhome.com':
    network: '192.168.11.0'
    mask:    '255.255.255.0',
    range:   '19.168.11.100 19.168.11.199',
    gateway: '19.168.11.1',
}

# vim: sw=2:ai:nu expandtab
