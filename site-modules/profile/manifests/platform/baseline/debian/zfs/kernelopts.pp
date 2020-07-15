# @summary monthly reporting

class profile::platform::baseline::debian::zfs::kernelopts {

# Setting kernel options
# TODO: update_initramfs_all is still in profile::zfs_server
# TODO: can values be calculated from facts
#kmod::list_of_options:
# 'zfs_arc_max':
#    module:  'zfs'
#    option: 'zfs_arc_max'
#    #value: $::facts['memory']['system']['total_bytes']*7/10
#    value: 0
#    #notify: Exec['update_initramfs_all']
#  'zfs_arc_min':
#    module: 'zfs'
#    option: 'zfs_arc_min'
#    #value: $::facts['memory']['system']['total_bytes']*3/10
#    value: 0
#    #notify: Exec['update_initramfs_all']
#  'zfs_vdev_scheduler':
#    module: 'zfs'
#    option: 'zfs_vdev_scheduler'
#    value: 'noop'
#    #notify: Exec['update_initramfs_all']
#  # use the prefetch method
#  'zfs_prefetch_disable':
#    module: 'zfs'
#    option: 'zfs_prefetch_disable'
#    value: 0
#    #notify: Exec['update_initramfs_all']
#  }
#  # max write speed to l2arc
#  # tradeoff between write/read and durability of ssd (?)
#  # default : 8 * 1024 * 1024
#  # setting here : 500 * 1024 * 1024
#  'l2arc_write_max':
#    module: 'zfs'
#    option: 'l2arc_write_max'
#    value: 524288000
#    #notify: Exec['update_initramfs_all']
#

  exec { 'update_initramfs_all':
    command     => '/usr/sbin/update-initramfs -k all -u',
    refreshonly => true,
  }
}
