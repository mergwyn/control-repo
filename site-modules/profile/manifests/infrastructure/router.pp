#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['openvpn','nordvpn','none'] $type = 'none',
) {

  include sysctl
  sysctl::configuration { 'net.ipv4.ip_forward':  value => '1', }

  include firewall
  resources { 'firewall': purge => true, }

  firewall {'100 FORWARD for eth0':
    chain   => 'FORWARD',
    source  => '10.58.0.0/16',
    iniface => 'eth0',
    jump    => 'ACCEPT',
  }
  firewall {'110 FORWARD for eth0.1':
    chain   => 'FORWARD',
    source  => '192.168.11.0/24',
    iniface => 'eth0.1',
    jump    => 'ACCEPT',
  }
  firewall {'200 nat for eth0':
    table   => 'nat',
    chain   => 'POSTROUTING',
    iniface => 'eth0',
    jump    => 'MASQUERADE',
  }
  firewall {'210 nat for eth0.1':
    table   => 'nat',
    chain   => 'POSTROUTING',
    iniface => 'eth0.1',
    jump    => 'MASQUERADE',
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
