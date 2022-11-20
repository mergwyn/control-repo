#
class role::media_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::ddclient
  include profile::app::sssd
  include profile::app::downloader
  include profile::app::zabbix::agent
  include profile::app::backuppc::client
}
