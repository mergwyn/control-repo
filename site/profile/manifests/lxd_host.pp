#

class profile::lxd_host {
  package { 'lxd': }
  service { 'lxd':
    ensure  => 'running',
    #enable  => true,
    require => Package['lxd'],
  }

  # lxd snap related commands
  vcsrepo { '/opt/code/lxdsnap':
      ensure   => latest,
      provider => git,
      require  => [ Package['git'] ],
      source   => 'https://github.com/nsyntych/lxdsnap.git',
      revision => 'master',
  }
  #TODO run make

  # now lxdsnap crontab related jobs
  file { '/usr/local/bin/lxdsnap_cron':
    ensure  => present,
    content => '
#!/bin/sh
/usr/src/lxdsnap/venv/bin/python /usr/src/lxdsnap/snap.py 2>&1 | 
  logger -t lxdsnap
status=$?
if [ $? -ne 0 ]
then
	logger -t lxdsnap -s "lxdsnap returned $status"
fi
',
    mode    => '0555',
  } ->
  cron { 'lxdsnap':
    command => '/usr/local/bin/lxdsnap_cron',
    user    => 'root',
    minute  => 4,
  }
  file { '/etc/cron.hourly/lxdsnap': ensure -> absent, }

  file { 'usr/local/bin/upgrade_lxd':
    ensure => present,
    mode   => '0555',
  }
}
# vim: sw=2:ai:nu expandtab
