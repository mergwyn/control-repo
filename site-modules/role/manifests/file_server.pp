# @summary File server role
#
# Providing ZFS-backed NFS, Samba, MinIO, Time Machine, and container hosting with backup support
#
class role::file_server {
  include profile::platform::baseline
  include profile::platform::baseline::debian::autofs
  include profile::platform::baseline::debian::nfs_server
  include profile::platform::baseline::debian::virtual::kubernetes
  include profile::platform::baseline::debian::zfs
  include profile::platform::baseline::debian::virtual::lxd

  include profile::openvox::dev

  include profile::app::cloudflared
  include profile::app::gpo::clean
  include profile::app::k8s_tools
  include profile::app::kopia
  include profile::app::lxd::backup
  include profile::app::minio
  include profile::app::samba::shares
  include profile::app::sssd
  include profile::app::timemachine
  include profile::app::transcoder
  include profile::app::unison
}
