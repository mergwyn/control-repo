#
class role::vpn_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::openvpn
  include profile::app::keepalived::vpn
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
