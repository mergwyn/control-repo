#
class role::k8s_server {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::platform::baseline::debian::zfs
  include profile::app::sssd
  include profile::platform::baseline::debian::virtual::kubernetes
  include profile::platform::baseline::debian::virtual::lxd
  include profile::app::lxd::backup

  #include profile::app::zabbix::agent
  #include profile::app::backuppc::client
  include profile::app::unison
  include profile::app::kopia
  include profile::app::k8s_tools
  include profile::app::velero
  #include profile::app::mayastor
}
