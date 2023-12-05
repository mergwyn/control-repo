#
#
class profile::platform::baseline::debian::zfs::backup
{
  $scripts='/etc/backuppc-scripts/'
  $preuser="${scripts}DumpPreUser/"
  $postuser="${scripts}DumpPostUser/"

  file { "${preuser}/S40zfs_props":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S40zfs_props',
    mode   => '0555',
  }
}
