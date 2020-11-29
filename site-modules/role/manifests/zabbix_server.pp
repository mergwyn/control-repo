#
class role::zabbix_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::sssd
  include profile::app::zabbix::server
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
