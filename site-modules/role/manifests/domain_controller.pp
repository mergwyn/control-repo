#
class role::domain_controller {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::dhcpd
  include profile::app::sssd
  include profile::app::samba::dc
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
