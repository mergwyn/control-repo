#
# TODO: sudo configuration

class profile::zfs_server {

  file { "/usr/local/bin/zfs_report.sh":
    ensure  => present,
    source  => "puppet:///modules/profile/zfs/zfs_report.sh",
    mode    => '0775',
  }
  file { "/etc/cron.monthly/zfs-montly-report.sh":
    ensure  => present,
    content  => "#!/bin/sh\n/usr/local/bin/zfs_report.sh\n",
    mode    => '0775',
  }
  #file { "/etc/zabbix/zabbix_agentd.d/zfs-auto.conf.conf": ensure => absent }
  #file { "/etc/zabbix/zabbix_agentd.d/zfs-health.conf.conf": ensure => absent }

  zabbix::userparameters { 'zfs-auto':
    source => "puppet:///modules/profile/zfs/zfs-auto.conf",
  }
  zabbix::userparameters { 'zfs-health':
    content => 'UserParameter=zpool.health[*],sudo zpool list -H -o health $1',
  }

  file { "/etc/sudoers.d/zabbix-zfs":
    ensure  => present,
    content  => "
Defaults:zabbix	!requiretty
zabbix	ALL=(root)	NOPASSWD:	/sbin/zpool
zabbix	ALL=(root)	NOPASSWD:	/sbin/zfs
",
    mode    => '0440',
  }

}
# vim: sw=2:ai:nu expandtab
