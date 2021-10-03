#
# TODO: complete testing of settings setup
# TODO: most of this is not used anymore - convert to odrive
#
class profile::app::photos {
  apt::ppa { 'ppa:nilarimogard/webupd8':
    #package_manage => true
  }

  package { 'grive':
    ensure  => present,
    require => Apt::Ppa['ppa:nilarimogard/webupd8'],
  }

  package { [ 'exiftran', 'exiv2' ]: }

  include profile::app::scripts
  $codedir='/opt/scripts'

  cron::job {'photo-upload':
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"'],
    command     => "${codedir}/bin/google_upload",
    user        => 'gary',
    minute      => '35',
    hour        => '*/3',
  }
}
