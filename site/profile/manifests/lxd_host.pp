#

class profile::lxd_host {
  package { 'lxd': }
  package { 'crie': }
  package { 'bridge-utils': }
  package { 'git': }
  service { 'lxd':
    ensure  => 'running',
    #enable  => true,
    require => Package['lxd'],
  }

  $installdir='/opt/code/lxdsnap'

  # lxd snap related commands
  vcsrepo { $installdir:
      ensure   => present,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/nsyntych/lxdsnap.git',
      revision => 'master',
      notify   => Exec['build-lxdsnap'],
  }
  file { '/usr/local/bin/build_lxdsnap':
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/build_lxdsnap',
  }
  exec { 'build-lxdsnap':
    cwd         => $installdir,
    path        => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command     => "build_lxdsnap ${installdir}",
    timeout     => 600, # 10 minutes
    require     => File['/usr/local/bin/build_lxdsnap'],
    refreshonly => true,
  }

  # now lxdsnap crontab related jobs
  file { '/usr/local/bin/lxdsnap_cron':
    ensure  => present,
    mode    => '0555',
    content => "#!/bin/bash
python ${installdir}/snap.py 2>&1 | logger -t lxdsnap
status=\$?
[[ \${status} -ne 0 ]] && 
	logger -t lxdsnap -s \"lxdsnap returned \$status\"
",
  }

  include cron
  cron::job { 'lxdsnap':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => '/usr/local/bin/lxdsnap_cron',
    user        => 'root',
    minute      => 4,
  }
  file { '/etc/cron.hourly/lxdsnap': ensure => absent, }

  file { '/usr/local/bin/upgrade_lxd':
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/upgrade_lxd'
  }
}
# vim: sw=2:ai:nu expandtab
