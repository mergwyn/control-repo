#
class role::lxd_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::platform::baseline::debian::zfs
  include profile::app::sssd
  include profile::platform::baseline::debian::virtual::lxd
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
