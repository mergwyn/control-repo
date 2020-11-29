#

class profile::platform::baseline::debian::virtual::lxd {
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

  include profile::app::git

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
    environment => [ 'PATH="usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"', ],
    command     => '/opt/lxdbackup/lxdbackup',
    user        => 'gary',
    minute      => fqdn_rand(59, 'lxdbackup'),
    hour        => fqdn_rand(5, 'lxdbackup'),
  }

  # support for openwrt backup as part of backuppc run
  $scripts='/etc/backuppc-scripts/'
  $preuser="${scripts}DumpPreUser/"
  $postuser="${scripts}DumpPostUser/"

  file { "${preuser}/S31openwrt_backup":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S31openwrt_backup',
    mode   => '0555',
  }
  file { "${postuser}/P31openwrt_clean":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/P31openwrt_clean',
    mode   => '0555',
  }

  $lxdscripts = [
    'allcontainers',
    'allhosts',
    'allremotes',
    'listcontainers',
    'listremotes',
    'upgrade_lxd'
  ]

  $lxdscripts.each |String $lxdscript| {
    file {"${bindir}/${lxdscript}":
      ensure => present,
      mode   => '0555',
      source => "puppet:///modules/profile/lxd/${lxdscript}",
    }
  }

}
