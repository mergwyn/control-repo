#
class role::router {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::infrastructure::router
  include profile::zabbix::agent
  include profile::app::backuppc::client
}
