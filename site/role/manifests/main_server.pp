#
class role::main_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::domain::sso
  include profile::nfs_server
  include profile::backuppc::server
  include profile::web::webdav
  include profile::photos
  include profile::mac::timemachine_server
  include profile::virtual::lxd
  include profile::zabbix::agent
  include profile::backuppc::client
}