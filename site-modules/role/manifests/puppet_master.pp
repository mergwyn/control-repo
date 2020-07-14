#
class role::puppet_master {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::puppet::server
  include profile::puppet::agent
  include profile::zabbix::agent
  include profile::app::backuppc::client
}
