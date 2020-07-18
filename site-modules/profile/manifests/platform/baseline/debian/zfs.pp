# @summary Wrapper for zfs support

class profile::platform::baseline::debian::zfs {

  include profile::platform::baseline::debian::zfs::autosnapshot
  include profile::platform::baseline::debian::zfs::default
  include profile::platform::baseline::debian::zfs::grub
  include profile::platform::baseline::debian::zfs::kernelopts
  include profile::platform::baseline::debian::zfs::reporting
  include profile::platform::baseline::debian::zfs::zabbix
  include profile::platform::baseline::debian::zfs::trim

}
