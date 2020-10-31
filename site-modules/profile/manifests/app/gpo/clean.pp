#
class profile::app::gpo::clean {

  $codedir   = '/opt/'
  $owner     = 'gary'

  # cron job to run scripts
  include cron
  include profile::scripts

  cron::job { 'GPO':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => "test -x ${scriptdir}/bin/GPO_backup && ${scriptdir}/bin/GPO_backup",
    user        => $owner,
    minute      => 5,
    hour        => '0-18',
  }

}
