#
class role::zabbix_server {
  include profile::profile::baseline  # All roles should have the base profile
  include profile::domain::sso
  include profile::zabbix::server
  include profile::zabbix::agent
  include profile::backuppc::client
}
