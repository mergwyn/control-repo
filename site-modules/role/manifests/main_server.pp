#
class role::main_server {
  include profile::platform::baseline
  include profile::platform::baseline::debian::autofs
  include profile::platform::baseline::debian::nfs_server
  include profile::platform::baseline::debian::virtual::kubernetes
  include profile::platform::baseline::debian::zfs
  include profile::platform::baseline::debian::virtual::lxd

  include profile::openvox::dev

  include profile::app::gpo::clean
  include profile::app::iptv
  include profile::app::k8s_tools
  include profile::app::kopia
  include profile::app::lxd::backup
  include profile::app::nginx::phonebook
  include profile::app::nginx::webdav
  include profile::app::odrive
  include profile::app::photos
  include profile::app::samba::shares
  include profile::app::speedtest
  include profile::app::sssd
  include profile::app::timemachine
  include profile::app::transcoder
  include profile::app::unison
}
