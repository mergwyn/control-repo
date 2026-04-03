#
#
class profile::platform::baseline::debian::zfs::backup {
  # support for samba backup as part of kopia run
  $scripts='/etc/kopia'
  $preuser="${scripts}/snap-before"
  $postuser="${scripts}/snap-after"

  file { "${preuser}/S40zfs_props":
    ensure => file,
    source => 'puppet:///modules/profile/backuppc/S40zfs_props',
    mode   => '0555',
  }
}
