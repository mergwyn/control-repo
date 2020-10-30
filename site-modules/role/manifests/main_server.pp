#
class role::main_server {
  include profile::platform::baseline
  include profile::platform::baseline::debian::zfs

  include profile::domain::sso
  include profile::zabbix::agent
  include profile::virtual::lxd

  include profile::app::backuppc::server
  include profile::app::backuppc::client
  include profile::app::gpo::clean
  include profile::app::timemachine
  include profile::app::samba::shares
  include profile::app::nginx::webdav
  include profile::nfs_server
  include profile::photos
}
