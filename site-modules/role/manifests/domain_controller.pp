#
class role::domain_controller {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::network::dhcpd
  include profile::domain::sso
  include profile::app::samba::dc
  include profile::zabbix::agent
  include profile::app::backuppc::client
}