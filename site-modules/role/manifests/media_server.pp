#
class role::media_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::domain::sso
  include profile::media::transcoder
  include profile::app::downloader
  include profile::zabbix::agent
  include profile::app::backuppc::client
}
