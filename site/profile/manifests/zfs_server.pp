#
# TODO: sudo configuration

class profile::zfs_server {

  # monthly report
  file { '/usr/local/bin/zfs_report.sh':
    ensure => present,
    source => 'puppet:///modules/profile/zfs/zfs_report.sh',
    mode   => '0775',
  }
  file { '/etc/cron.monthly/zfs-montly-report.sh': ensure  => absent, }
  file { '/etc/cron.monthly/zfs-montly-report':
    ensure  => present,
    content => "#!/bin/sh\n/usr/local/bin/zfs_report.sh\n",
    mode    => '0775',
  }

  # grub menu generation
  file { '/etc/grub.d/42_zfs_select':
    ensure => present,
    source => 'puppet:///modules/profile/zfs/42_zfs_select',
    mode   => '0755',
  }
  file { '/etc/grub.d/43_zfs_snap':
    ensure => present,
    source => 'puppet:///modules/profile/zfs/43_zfs_snap',
    mode   => '0755',
  }
  file { '/etc/cron.daily/grubupdate':
    ensure  => present,
    content => "#!/bin/bash\n\n update-grub 2>&1 | logger -t update-grub -i\n"
    mode    => '0555',
  }

  # zabbix support
  zabbix::userparameters { 'zfs-auto':
    source => 'puppet:///modules/profile/zfs/zfs-auto.conf',
  }
  zabbix::userparameters { 'zfs-health':
    content => "UserParameter=zpool.health[*],sudo zpool list -H -o health \${1}\n",
  }

  file { '/etc/sudoers.d/zabbix-zfs':
    ensure  => present,
    content => "
Defaults:zabbix	!requiretty
zabbix	ALL=(root)	NOPASSWD:	/sbin/zpool
zabbix	ALL=(root)	NOPASSWD:	/sbin/zfs
",
    mode    => '0440',
  }

}
# vim: sw=2:ai:nu expandtab
