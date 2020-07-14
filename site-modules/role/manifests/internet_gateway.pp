#
class role::internet_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::ddclient
  include profile::app::reverse_proxy
  include profile::zabbix::agent
  include profile::app::backuppc::client
}
