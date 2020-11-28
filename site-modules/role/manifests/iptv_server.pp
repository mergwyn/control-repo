#
class role::iptv_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::sssd
  include profile::app::iptv
  include profile::zabbix::agent
  include profile::app::backuppc::client
}
