#
#
class profile::platform::baseline::debian::zfs::backup {
  # support for samba backup as part of kopia run
  $snapbefore = lookup('profile::app::kopia::client::snapbefore')
  $snapafter = lookup('profile::app::kopia::client::snapafter')

  file { "${snapbefore}/S40zfs_props":
    ensure => file,
    source => 'puppet:///modules/profile/backuppc/S40zfs_props',
    mode   => '0555',
  }

  profile::app::kopia::path_policy { '/var/backups':
    before_snapshot => ["${snapbefore}/S40zfs_props"],
  }
}
