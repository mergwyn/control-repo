# @summary kernel options (mainly tuning)
#
class profile::platform::baseline::debian::zfs::kernelopts {

# settings (percentage)
  $max = 0.3
  $min = 0.1

  kmod::option { 'zfs_arc_max':
    module => 'zfs',
    option => 'zfs_arc_max',
    value  => $::facts['memory']['system']['total_bytes']*$max,
    notify => Exec['update_initramfs_all'],
  }
  kmod::option { 'zfs_arc_min':,
    module => 'zfs',
    option => 'zfs_arc_min',
    value  => $::facts['memory']['system']['total_bytes']*$min,
    notify => Exec['update_initramfs_all'],
  }
#  kmod::option { 'zfs_vdev_scheduler':,
#    module => 'zfs',
#    option => 'zfs_vdev_scheduler',
#    value => 'noop',
#    notify => Exec['update_initramfs_all'],
#   use the prefetch method,
#  }
#  kmod::option { 'zfs_prefetch_disable':,
#    module => 'zfs',
#    option => 'zfs_prefetch_disable',
#    value => 0,
#    notify => Exec['update_initramfs_all'],
#  },
#   max write speed to l2arc,
#   tradeoff between write/read and durability of ssd (?),
#   default  => 8 * 1024 * 1024,
  kmod::option { 'l2arc_write_max':,
    module => 'zfs',
    option => 'l2arc_write_max',
    value  => 500*1024*1024,
    notify => Exec['update_initramfs_all'],
  }

  exec { 'update_initramfs_all':,
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true,
  }
}
