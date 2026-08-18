# @summary Private: dracut configuration required to build ZFSBootMenu images
#
# @api private
#
# @description
# Not intended to be included directly - this is `contain`ed by
# profile::platform::baseline::debian::boot::zfsbootmenu, which is the only
# thing that depends on it. It previously existed as a standalone top-level
# class (`boot::dracut`) that every Debian baseline node included
# regardless of whether it ran ZFSBootMenu; folding it in here means the
# dracut/zfs-dracut packages and the ZBM-specific dracut.conf.d file only
# ever get installed on nodes that actually need them, with no separate
# fact-guard to keep in sync.
#
# This class:
#
# * Ensures the ZFS dracut module is available
# * Includes /etc/hostid inside generated initramfs images
#
# @example
#   contain profile::platform::baseline::debian::boot::zfsbootmenu::dracut_setup
#
class profile::platform::baseline::debian::boot::zfsbootmenu::dracut_setup {
  package { ['dracut', 'zfs-dracut']:
    ensure => installed,
  }

  file { '/etc/dracut.conf.d/99-zfsbootmenu.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("EOF"/L),
      install_items+=" /etc/hostid /etc/zfs/zpool.cache "
      force_dracutmodules+=" zfs "
      hostonly="no"
      | EOF
    require => Package['dracut'],
    notify  => Exec['rebuild_initramfs'],
  }
}
