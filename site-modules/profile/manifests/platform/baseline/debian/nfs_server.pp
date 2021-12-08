#
#
class profile::platform::baseline::debian::nfs_server {
  package { 'nfs-kernel-server': }
  ->  service {'rpc-statd':
        ensure => running,
        enable => true,
      }
}
