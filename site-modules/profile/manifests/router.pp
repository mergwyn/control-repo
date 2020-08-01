#

class profile::router {

  include cron
  include profile::app::scripts
  $codedir='/opt/scripts'

  $aptpackages = [
    'ufw',
    'openvpn',
  ]
  package { $aptpackages: ensure   => present, }
  #
  #TODO configure ufw
  #TODO configure openvpn

  # make sure routes are up to date
  cron::job { 'iptv-routes':
    command     => "test -x ${codedir}/iptv/getroutes && ${codedir}/iptv/getroutes",
    minute      => 30,
    hour        => '4,12,16',
    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
  }

}
