# @summary Set values in /etc/default/zfs

class profile::platform::baseline::debian::zfs::default {

  shellvar { 'ZFS_SHARE':
    ensure => present,
    target => '/etc/default/zfs',
    value  =>  'yes',
  }
  shellvar { 'ZFS_UNSHARE':
    ensure => present,
    target => '/etc/default/zfs',
    value  =>  'yes',
  }

}
