#
class role::puppet_master {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::puppet::server
  include profile::puppet::agent
  include profile::puppet::dev
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
