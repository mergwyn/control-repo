# @summary
#   Ensures ZFSBootMenu images are regenerated automatically after
#   kernel updates.
#
# ZFSBootMenu images (initramfs/vmlinuz on the ESP) are not regenerated
# automatically by any built-in package hook. Without this, an image can
# silently go stale after kernel or zfs-dkms updates, eventually causing
# the pool to be mountable read-only or not at all if pool features move
# ahead of what the stale image's ZFS module understands (see hotel
# incident, 2026-08: image dated 2023 could not import a pool upgraded
# with zpool upgrade, requiring recovery via external live media).
#
# This class installs a kernel postinst.d hook that calls generate-zbm
# whenever a new kernel package is installed, keeping the boot image
# current going forward.
#
# Hosts without ZFSBootMenu installed are skipped automatically via the
# has_zfsbootmenu custom fact, so this class is safe to include broadly
# without needing to maintain a manual list of applicable nodes.
#
# @example Basic usage
#   include platform::baseline::debian::boot::zbm_regen
class profile::platform::baseline::debian::boot::zbm_regen {
  if $facts['has_zfsbootmenu'] {
    file { '/etc/kernel/postinst.d/60-zfsbootmenu':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => epp('profile/boot/zbm_regen_hook.epp'),
    }
  } else {
    notify { 'zfsbootmenu_not_present':
      message => "platform::baseline::debian::boot::zbm_regen: skipped, generate-zbm not found on ${trusted['certname']}",
    }
  }
}
