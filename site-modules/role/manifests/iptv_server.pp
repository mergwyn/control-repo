#
class role::iptv_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::platform::baseline::debian::virtual::docker

  include profile::app::sssd
  include profile::app::iptv
  include profile::app::speedtest
  include profile::app::transcoder
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
