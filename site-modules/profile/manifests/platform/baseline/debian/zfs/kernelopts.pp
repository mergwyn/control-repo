# @summary kernel options (mainly tuning)
#
class profile::platform::baseline::debian::zfs::kernelopts {

  # Calculate ARC max: ~12% of total RAM, but with sensible floors/caps
  $mem_total_bytes = $facts['memory']['system']['total_bytes']

  $zfs_arc_bytes = $mem_total_bytes ? {
    # If < 10GB (8GB NUCs), set to 1GB
    /^[0-9]{1,10}$/ if $mem_total_bytes < 10737418240 => '1073741824',

    # If < 20GB (16GB NUCs), set to 2GB
    /^[0-9]{1,11}$/ if $mem_total_bytes < 21474836480 => '2147483648',

    # If 32GB or more, set to 4GB
    default                                          => '4294967296',
  }

  if $mem_total_bytes >
  kmod::option { 'zfs_arc_max':
    module => 'zfs',
    option => 'zfs_arc_max',
    value  => $zfs_arc_bytes,
    notify => Exec['update_initramfs_all'],
  }
  kmod::option { 'zfs_arc_min':
    module => 'zfs',
    option => 'zfs_arc_min',
    value  => 0,
    notify => Exec['update_initramfs_all'],
  }
#  kmod::option { 'zfs_vdev_scheduler':,
#    module => 'zfs',
#    option => 'zfs_vdev_scheduler',
#    value => 'noop',
#    notify => Exec['update_initramfs_all'],
#   use the prefetch method,
#  }
  kmod::option { 'zfs_prefetch_disable':
    module => 'zfs',
    option => 'zfs_prefetch_disable',
    value  => 0,
    notify => Exec['update_initramfs_all'],
  }
#   max write speed to l2arc,
#   tradeoff between write/read and durability of ssd (?),
#   default  => 8 * 1024 * 1024,
  kmod::option { 'l2arc_write_max':
    module => 'zfs',
    option => 'l2arc_write_max',
    value  => 500*1024*1024,
    notify => Exec['update_initramfs_all'],
  }

  exec { 'update_initramfs_all':
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true,
  }
}
