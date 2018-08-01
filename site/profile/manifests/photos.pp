#
# TODO: complete testing of settings setup

class profile::grive (
  apt::ppa { 'ppa:nilarimogard/webupd8':
    package_manage => true
  }

  package { 'grive':
    ensure  => present,
    require => Apt::Ppa['ppa:nilarimogard/webupd8'],
  }

  cron::job {'photo-upload':
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"'],
    command     => '/home/gary/photos/google_upload',
    user        => 'gary',
    minute      => '35',
    hour        => '*/2',
  }
}
# vim: sw=2:ai:nu expandtab
