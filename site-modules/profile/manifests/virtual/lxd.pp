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

  include profile::app::scripts
  include cron
  cron::job { 'lxdbackup':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => '/opt/scripts/bin/lxdbackup',
    user        => 'gary',
    minute      => 45,
    hour        => 2,
  }

#'  include profile::git
#'
#'  $codedir='/opt/code/lxdsnap'
#'
#'  # lxd snap related commands
#'  vcsrepo { $codedir:
#'      ensure   => latest,
#'      provider => git,
#'      require  => Package['git'],
#'      source   => 'https://github.com/nsyntych/lxdsnap.git',
#'      revision => 'master',
#'      notify   => Exec['build-lxdsnap'],
#'  }
#'  file { "${bindir}/build_lxdsnap":
#'    ensure => present,
#'    mode   => '0555',
#'    source => 'puppet:///modules/profile/build_lxdsnap',
#'  }
#'  exec { 'build-lxdsnap':
#'    cwd     => $codedir,
#'    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
#'    command => "build_lxdsnap ${codedir}",
#'    timeout => 600, # 10 minutes
#'    require => File["${bindir}/build_lxdsnap"],
#'    creates => "${codedir}/build.done",
#'  }
#'
#'  # now lxdsnap crontab related jobs
#'  file { "${bindir}/lxdsnap_cron":
#'    ensure  => present,
#'    mode    => '0555',
#'    content => "#!/bin/bash
#'python3 ${codedir}/snap.py 2>&1 | logger -t lxdsnap
#'status=\$?
#'[[ \${status} -ne 0 ]] && 
#'	logger -t lxdsnap -s \"lxdsnap returned \$status\"
#'",
#'  }
#'
#'  include cron
#'  cron::job { 'lxdsnap':
#'    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
#'    command     => "${bindir}/lxdsnap_cron",
#'    user        => 'root',
#'    minute      => 4,
#'  }
#'  file { '/etc/cron.hourly/lxdsnap': ensure => absent, }

  file { "${bindir}/upgrade_lxd":
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/upgrade_lxd'
  }
}
