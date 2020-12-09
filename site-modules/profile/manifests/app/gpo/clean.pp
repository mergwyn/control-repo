#
class profile::app::gpo::clean {

  $scriptdir = '/opt/scripts'
  $owner     = 'gary'

  # dependencies
  include cron
  include profile::app::scripts
  package {'xml2': }

  cron::job { 'GPO':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => "test -x ${scriptdir}/bin/GPO_backup && ${scriptdir}/bin/GPO_backup",
    user        => $owner,
    minute      => 5,
    hour        => '0-18',
  }

}
