#

class profile::zfs_server {
  exec { 'update_initramfs_all':
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true,
  }
}
