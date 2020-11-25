#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['openvpn','nordvpn'] $type = 'openvpn',
) {

  case $type  {
    'openvpn': { include profile::infrastructure::router::openvpn }
    'nordvpn': { include profile::infrastructure::router::nordvpn }
    default:   { fail("${type} is not supported") }
  }

  if $iptv {
    include cron
    include profile::app::scripts
    $codedir='/opt/scripts'

    # make sure routes are up to date
    cron::job { 'iptv-routes':
      command     => "test -x ${codedir}/iptv/getroutes && ${codedir}/iptv/getroutes",
      minute      => 30,
      hour        => '4,12,16',
      environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
    }
  }

}
