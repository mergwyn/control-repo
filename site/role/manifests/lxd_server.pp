#
class role::lxd_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::platform::baseline::debian::zfs
  include profile::domain::sso
  include profile::virtual::lxd
  include profile::zabbix::agent
  include profile::backuppc::client
}
