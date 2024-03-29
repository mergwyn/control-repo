#
#
class profile::app::avahi {

  package { 'avahi-daemon-install':
    name            => 'avahi-daemon',
    install_options => ['-o', 'DPkg::Options=NoTriggers'],
  }

  ini_setting { '[rlimits] rlimit-nproc':
    ensure  => absent,
    setting => 'rlimit-nproc',
    section => 'rlimits',
    path    => '/etc/avahi/avahi-daemon.conf',
    require => Exec['avahi-daemon-install'],
    notify  => Service['avahi-daemon'],
  }

  exec { 'avahi-daemon-install':
    command     => '/usr/bin/dpkg --configure -a',
    refreshonly => true,
    notify      => Service['avahi-daemon'],
  }

  service { 'avahi-daemon':
    ensure => 'running',
    enable => true,
  }
}

# vim: sw=2:ai:nu expandtab
