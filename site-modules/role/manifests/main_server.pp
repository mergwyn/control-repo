#
class role::main_server {
  include profile::platform::baseline
  include profile::platform::baseline::debian::zfs
  include profile::platform::baseline::debian::nfs_server

  include profile::puppet::dev

  include profile::app::sssd
  include profile::app::zabbix::agent
  include profile::platform::baseline::debian::autofs
  include profile::platform::baseline::debian::virtual::lxd
  include profile::platform::baseline::debian::virtual::kubernetes

  include profile::app::backuppc::client
  include profile::app::backuppc::server
  include profile::app::gpo::clean
  include profile::app::iptv
  include profile::app::nginx::webdav
  include profile::app::nginx::phonebook
  include profile::app::odrive
  include profile::app::photos
  include profile::app::samba::shares
  include profile::app::speedtest
  include profile::app::timemachine
  include profile::app::transcoder
  include profile::app::unison
  include profile::app::kopia

}
