#

class profile::app::iptv {
  include cron
  include profile::app::scripts

  $codedir='/opt/scripts'

  $packages = [ 'socat' ]
  package { $packages: ensure => present }

#  class{'::tvheadend':
#    release        => 'stable',
#    admin_password => lookup('secrets::tvheadend'),
#  }

# TODO replace with timer - cron job doesn't run correctly (curl error)
#  cron::job::multiple { 'xmltv':
#    jobs        => [
##      {
##        command => "test -x ${codedir}/iptv/get-epg && ${codedir}/iptv/get-epg",
##        minute  => 30,
##        hour    => '*',
##      },
#      {
#        command => "test -x ${codedir}/iptv/get-channels && ${codedir}/iptv/get-channels",
#        minute  => 20,
#        hour    => '*/6',
#      },
#    ],
#    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"' ],
#  }

  #TODO xteve?
  include profile::app::nginx::xmltv
}
