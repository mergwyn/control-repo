#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['openvpn','nordvpn','none'] $type = 'none',
) {

  class { 'firewalld':
    default_zone         => 'internal',
    default_service_zone => 'public',
    default_port_zone    => 'public',
  }
  firewalld_zone { 'internal':
    interfaces => ['eth0'],
  }
  firewalld_zone { 'public':
    interfaces => ['tun0'],
  }

#  class { 'ufw':
#    forward       => 'ACCEPT',
#    deny_incoming => true,
#  }
#
#  # Disable IPv6
#  shellvar { 'IPV6':
#    ensure    => present,
#    value     => 'no',
#    target    => '/etc/default/ufw',
#    uncomment => true,
#    notify    => Service['ufw'],
#    require   => Package['ufw']
#  }
#
## Add forward rule
#  ini_setting { 'net.ipv4.ip_forward':
#    ensure  => present,
#    path    => '/etc/ufw/sysctl.conf',
#    setting => 'net/ipv4/ip_forward',
#    value   => '1',
#    notify  => Service['ufw'],
#    require => Package['ufw']
#  }
#
## Rules
#  ufw::allow { 'allow-in-from-local':
#    direction => 'IN',
#    from      => '10.58.0.0/16',
#  }
#  ufw::allow { 'allow-out-to-local':
#    direction => 'OUT',
#    to        => '10.58.0.0/16',
#  }
#
## allow vpn connection to be established
#  ufw::allow { 'allow-out-to-vpn-1194':
#    direction => 'OUT',
#    port      => '1194',
#  }
#  ufw::allow { 'allow-out-to-vpn-1195':
#    direction => 'OUT',
#    port      => '1195',
#  }

#ufw allow out on ${tun} from any to any
#iptables -t nat --flush
#iptables -t nat --delete-chain
#iptables -P OUTPUT DROP
#iptables -A INPUT -j ACCEPT -i lo
#iptables -A OUTPUT -j ACCEPT -o lo
#iptables -A OUTPUT -j ACCEPT -d 169.38.69.24/32 -o wlp6s0 -p udp -m udp --dport 1194
#iptables -A INPUT -j ACCEPT -s 169.38.69.24/32 -i wlp6s0 -p udp -m udp --sport 1194
#iptables -A INPUT -j ACCEPT -i tun0
#iptables -A OUTPUT -j ACCEPT -o tun0

# allow traffic on tun0
#  firewall {'100 allow traffic in on tun0':
#    chain   => 'INPUT',
#    iniface => 'tun0',
#    action  => 'accept',
#  }
#  firewall {'101 allow traffic out on tun0':
#    chain    => 'OUTPUT',
#    outiface => 'tun0',
#    action   => 'accept',
#  }
#
#
#
#  include firewall
#  resources { 'firewall': purge => true, }
#
#  firewall {'100 FORWARD for eth0':
#    chain   => 'FORWARD',
#    source  => '10.58.0.0/16',
#    proto   => 'all',
#    iniface => 'eth0',
#    action  => 'accept',
#  }
#  firewall {'110 FORWARD for eth0.1':
#    chain   => 'FORWARD',
#    source  => '192.168.11.0/24',
#    proto   => 'all',
#    iniface => 'eth0.1',
#    action  => 'accept',
#  }
#  firewall {'200 nat for eth0':
#    table    => 'nat',
#    chain    => 'POSTROUTING',
#    outiface => 'eth0',
#    proto    => 'all',
#    jump     => 'MASQUERADE',
#  }
#  firewall {'210 nat for eth0.1':
#    table    => 'nat',
#    chain    => 'POSTROUTING',
#    outiface => 'eth0.1',
#    proto    => 'all',
#    jump     => 'MASQUERADE',
#  }

  case $type  {
    'none':    { }
    'nordvpn': { include profile::infrastructure::router::nordvpn }
    'nordvpn': { include profile::infrastructure::router::nordvpn }
    default:   { fail("${type} is not supported") }
  }

# TODO remove this
#  if $iptv {
#    include cron
#    include profile::app::scripts
#    $codedir='/opt/scripts'
#
#    # make sure routes are up to date
#    cron::job { 'iptv-routes':
#      command     => "test -x ${codedir}/iptv/getroutes && ${codedir}/iptv/getroutes",
#      minute      => 30,
#      hour        => '4,12,16',
#      environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
#    }
#  }

}
