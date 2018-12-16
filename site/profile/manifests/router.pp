#

class profile::router {

  include cron
  include profile::scripts
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
    minute      => 51,
    hour        => '*/4',
    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
  }

}
#
# vim: sw=2:ai:nu expandtab
