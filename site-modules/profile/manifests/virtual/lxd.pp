#

class profile::virtual::lxd {
  package { [ 'bridge-utils' ]: }
  package { [ 'criu' ]: ensure => absent, }

  include ::snapd
  package { 'lxd':
    ensure   => latest,
    provider => snap,
  }
  exec { 'enable-criu':
    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command => 'snap set lxd criu.enable=true',
    onlyif  => 'test `snap get lxd criu.enable` -eq false',
    require => Package['lxd'],
    notify  => Exec['snap.lxd.daemon.service'],
  }
  Exec { 'snap.lxd.daemon.service':
    path        => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command     => 'snap run --command=reload lxd.daemon',
    require     => Package['lxd'],
    refreshonly => true,
  }

  $bindir='/usr/local/bin'

  include profile::git

  $codedir='/opt/lxdbackup'

  vcsrepo { $codedir:
      ensure   => latest,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/lxdbackup.git',
      revision => 'master',
  }

  include profile::app::scripts
  include cron
  cron::job { 'lxdbackup':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => '/opt/scripts/bin/lxdbackup',
    user        => 'gary',
    minute      => fqdn_rand(59, 'lxdbackup'),
    hour        => fqdn_rand(5, 'lxdbackup'),
  }

  file { "${bindir}/upgrade_lxd":
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/upgrade_lxd'
  }
}
