#
# TODO: complete testing of settings setup

class profile::photos {
  apt::ppa { 'ppa:nilarimogard/webupd8':
    #package_manage => true
  }

  package { 'grive':
    ensure  => present,
    require => Apt::Ppa['ppa:nilarimogard/webupd8'],
  }

  package { [ 'exiftran', 'exiv2' ]: }

  cron::job {'photo-upload':
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"'],
    command     => '/home/gary/photos/google_upload',
    user        => 'gary',
    minute      => '35',
    hour        => '*/3',
  }
}
# vim: sw=2:ai:nu expandtab
