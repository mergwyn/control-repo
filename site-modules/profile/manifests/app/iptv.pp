#

class profile::app::iptv {
  include cron
  include profile::scripts

  $codedir='/opt/scripts'

  $packages = [ 'curl', 'socat' ]
  package { $packages: ensure => present }

#  class{'::tvheadend':
#    release        => 'stable',
#    admin_password => lookup('secrets::tvheadend'),
#  }

  cron::job::multiple { 'xmltv':
    jobs        => [
#      {
#        command => "test -x ${codedir}/iptv/get-epg && ${codedir}/iptv/get-epg",
#        minute  => 30,
#        hour    => '*',
#      },
      {
        command => "test -x ${codedir}/iptv/get-channels && ${codedir}/iptv/get-channels",
        minute  => 20,
        hour    => '4,12,16',
      },
    ],
    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
  }

  #TODO xteve?
  include profile::app::nginx::xmltv
}
