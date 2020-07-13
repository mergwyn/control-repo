#
class role::print_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::zabbix::agent
  include profile::app::backuppc::client
  include profile::print_server
}
