# @summary add grub menu to allow snapshot selection

class profile::platform::baseline::debian::zfs::grub {
  # Grub menu support
  file { '/etc/grub.d/42_zfs_select':
    ensure => present,
    source => 'puppet:///modules/profile/zfs/42_zfs_select',
    mode   => '0755',
  }
}
