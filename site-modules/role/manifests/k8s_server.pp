#
class role::k8s_server {
  include profile::platform::baseline  # All roles should have the base profile

  include profile::platform::baseline::debian::zfs
  include profile::platform::baseline::debian::virtual::kubernetes
  include profile::platform::baseline::debian::virtual::lxd
  include profile::platform::baseline::debian::nfs_server

  include profile::app::cloudflared
  include profile::app::k8s_tools
  include profile::app::kopia
  include profile::app::lxd::backup
  include profile::app::sssd
  include profile::app::unison
}
