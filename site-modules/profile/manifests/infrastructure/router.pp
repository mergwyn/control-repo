#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['openvpn','nordvpn','none'] $type = 'none',
) {

  class { 'ufw':
    forward => 'ACCEPT',
  }

  # Disable IPv6
  shellvar { 'IPV6':
    ensure    => present,
    value     => 'no',
    target    => '/etc/default/ufw',
    uncomment => true,
    notify    => Service['ufw'],
    require   => Package['ufw']
  }

# Add forward rule
  ini_setting { 'net.ipv4.ip_forward':
    ensure  => present,
    path    => '/etc/ufw/sysctl.conf',
    setting => 'net/ipv4/ip_forward',
    value   => '1',
    notify  => Service['ufw'],
    require => Package['ufw']
  }


# Rules
  ufw::allow { 'allow-all-from-trusted':
    from => '192.168.11.0/24',
    to   => 'any',
  }

#TODO: only needed for VPN?
  $nat_rule = "
# nat Table rules
*nat
:POSTROUTING ACCEPT [0:0]
 
# Forward traffic from eth1 through eth0.
-A POSTROUTING -s 10.0.125.0/24 -o eth1 -j MASQUERADE
 
# don't delete the 'COMMIT' line or these nat table rules won't be processed
COMMIT
"
#  file_line { 'ufw-ipv6':
#    line    => $nat_rule,
#    match   => '^IPV6=',
#    path    => '/etc//ufw/before.rules',
#    notify  => Service['ufw'],
#    require => Package['ufw']
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
