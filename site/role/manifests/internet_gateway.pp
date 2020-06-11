#
class role::internet_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::ddclient
  include profile::certificate_server
  include profile::zabbix::agent
  include profile::backuppc::client
  include nginx
}
