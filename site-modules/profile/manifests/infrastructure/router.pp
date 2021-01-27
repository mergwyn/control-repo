#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['openvpn','nordvpn','none'] $type = 'none',
) {

  $aptpackages = [
    'ufw',
  ]
  package { $aptpackages: ensure   => present, }


  # Enable UFW
  exec { 'ufw-enable':
    command => 'ufw --force enable',
    unless  => 'ufw status | grep -q "Status: active"',
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    require => Package['ufw']
  }

  # Define service
  service { 'ufw':
    ensure  => 'running',
    enable  => true,
    require => Package['ufw']
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

  # Set forward policy
  shellvar { 'DEFAULT_FORWARD_POLICY':
    ensure    => present,
    value     => 'ACCEPT',
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
  }

#TODO
  $nat_rule = "
# nat Table rules
*nat
:POSTROUTING ACCEPT [0:0]
 
# Forward traffic from eth1 through eth0.
-A POSTROUTING -s 10.0.125.0/24 -o eth1 -j MASQUERADE
 
# don't delete the 'COMMIT' line or these nat table rules won't be processed
COMMIT
"
  file_line { 'ufw-ipv6':
    line    => $nat_rule,
    match   => '^IPV6=',
    path    => '/etc//ufw/before.rules',
    notify  => Service['ufw'],
    require => Package['ufw']
  }



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
