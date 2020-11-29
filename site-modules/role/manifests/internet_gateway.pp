#
class role::internet_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::ddclient
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
  include profile::app::gateway
}
