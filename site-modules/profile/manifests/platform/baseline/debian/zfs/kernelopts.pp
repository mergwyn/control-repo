class profile::platform::baseline::debian::zfs::kernelopts (
  Float[0,1] $arc_percent = 0.25,
) {
  $mem_total_bytes = $facts['memory']['system']['total_bytes']

  $arc_candidate   = Integer($mem_total_bytes * $arc_percent)
  $arc_floor       = 1073741824    # 1GB
  $arc_ceiling     = 17179869184   # 16GB
  $zfs_arc_bytes   = max($arc_floor, min($arc_candidate, $arc_ceiling))

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

  kmod::option { 'zfs_prefetch_disable':
    module => 'zfs',
    option => 'zfs_prefetch_disable',
    value  => 0,
    notify => Exec['update_initramfs_all'],
  }

  kmod::option { 'l2arc_write_max':
    module => 'zfs',
    option => 'l2arc_write_max',
    value  => 524288000,
    notify => Exec['update_initramfs_all'],
  }

  exec { 'update_initramfs_all':
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true,
  }
}
