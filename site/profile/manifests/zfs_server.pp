#
# TODO: sudo configuration

class profile::zfs_server {

  include profile::git
  exec { 'zfs_share-a':
    command     => '/sbin/zfs share -a',
    refreshonly => true,
  }
  augeas { 'zfs.default':
    lens    => 'shellvars.lns',
    incl    => '/etc/default/zfs',
    context => '/files/etc/default/zfs',
    notify  => Exec['zfs_share-a'],
    changes => [
      'set ZFS_SHARE yes',
      'set ZFS_UNSHARE yes'
    ]
  }

  $codedir='/opt/code'
  $bindir='/usr/local/bin'
  $mandir='/usr/local/share/man'

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
    content => "#!/bin/bash\n\n update-grub 2>&1 | logger -t update-grub -i\n",
    mode    => '0555',
  }

  # zfs autosnap 
  vcsrepo { "${codedir}/zfs-auto-snapshot":
    ensure   => latest,
    provider => git,
    #source   => 'https://github.com/zfsonlinux/zfs-auto-snapshot',
    source   => 'https://github.com/mergwyn/zfs-auto-snapshot',
    revision => 'master',
    require  => Package['git', 'gawk'],
  }
  file { "${bindir}/zfs-auto-snapshot":
    ensure => present,
    mode   => '0755',
    source => "file://${codedir}/zfs-auto-snapshot/src/zfs-auto-snapshot.sh",
  }
  file { '/sbin/zfs-auto-snapshot': ensure => absent, }

  file { "${mandir}/man8": ensure => directory, }

  file { "${mandir}/man8/zfs-auto-snapshot.8":
    ensure => present,
    mode   => '0644',
    source => "file://${codedir}/zfs-auto-snapshot/src/zfs-auto-snapshot.8",
  }

  cron::job {'zfs-auto-snapshot':
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"'],
    command     => 'zfs-auto-snapshot --quiet --syslog --label=01 --keep=4  //',
    user        => 'root',
    minute      => '*/15',
  }
  file { '/etc/cron.hourly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0555',
    content => "#!/bin/sh\nexec zfs-auto-snapshot --quiet --syslog --label=02 --keep=24 //\n"
  }
  file { '/etc/cron.daily/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0555',
    content => "#!/bin/sh\nexec zfs-auto-snapshot --quiet --syslog --label=03 --keep=14 //\n"
  }
  file { '/etc/cron.weekly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0555',
    content => "#!/bin/sh\nexec zfs-auto-snapshot --quiet --syslog --label=04 --keep=8 //\n"
  }
  file { '/etc/cron.monthly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0555',
    content => "#!/bin/sh\nexec zfs-auto-snapshot --quiet --syslog --label=05 --keep=12 //\n"
  }

  # beadm boot environments

  # lxd snap related commands
  package { 'gawk': }
  vcsrepo { "${codedir}/beadm":
      ensure   => latest,
      provider => git,
      source   => 'https://github.com/TemptorSent/beadm',
      revision => 'master',
      require  => Package['git', 'gawk'],
  }
  file { "${bindir}/beadm":
    ensure => present,
    mode   => '0555',
    source => "file://${codedir}/beadm/beadm",
  }
  file { "${mandir}/man1": ensure => directory, }
  file { "${mandir}/man1/beadm.1":
    ensure => present,
    mode   => '0644',
    source => "file://${codedir}/beadm/beadm.1",
  }

  file { '/etc/default/beadm.conf':
    ensure => absent,
  }
  file { '/etc/beadm.conf':
    ensure  => present,
    mode    => '0555',
    content => "#\nGRUB=YES\n"
  }

  # zabbix support
  zabbix::userparameters { 'zfs-auto':
    source => 'puppet:///modules/profile/zfs/zfs-auto.conf',
  }
  zabbix::userparameters { 'zfs-health':
    content => "UserParameter=zpool.health[*],sudo zpool list -H -o health \${1}\n",
  }

  sudo::conf { 'zabbix-zpool':
    content => 'zabbix  ALL=(root)      NOPASSWD:       /sbin/zpool'
  }
  sudo::conf { 'zabbix-zfs':
    content => 'zabbix	ALL=(root)	NOPASSWD:	/sbin/zfs'
  }

  # set kernel parameters
  kmod::option { 'zfs_arc_max':
    module => 'zfs',
    option => 'zfs_arc_max',
    value  => $::facts['memory']['system']['total_bytes']/2,
    notify => Exec['update_initramfs_all']
  }
  kmod::option { 'zfs_arc_min':
    module => 'zfs',
    option => 'zfs_arc_min',
    value  => $::facts['memory']['system']['total_bytes']/4,
    notify => Exec['update_initramfs_all']
  }
  exec { 'update_initramfs_all':
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true
  }

}
# vim: sw=2:ai:nu expandtab
