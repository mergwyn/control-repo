#
class role::generic_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::domain::sso
  include profile::zabbix::agent
  include profile::backuppc::client
}
