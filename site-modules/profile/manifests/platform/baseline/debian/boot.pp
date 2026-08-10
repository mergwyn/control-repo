# @summary
#   Entry point for boot-related configuration on Debian-family physical nodes.
#
# @description
#   Boot-loader and initramfs configuration is split by *concern*, not by
#   tool:
#
#   * `boot::initramfs` — generic initramfs generation for nodes that are
#     NOT using ZFSBootMenu (plain dracut or initramfs-tools Debian systems,
#     and containers via the `none` provider).
#   * `boot::refind`     — the rEFInd boot manager itself: its own menu
#     timeout and the UEFI fallback copy.
#   * `boot::zfsbootmenu` — ZFSBootMenu end to end, including the
#     ZFSBootMenu-specific dracut setup it depends on (contained as a
#     private sub-class, `boot::zfsbootmenu::dracut_setup`) and the
#     `refind_linux.conf` boot stanza it hands to rEFInd.
#
#   All three top-level sub-classes self-guard via facts (`has_zfsbootmenu`,
#   `has_refind`, `initramfs_provider`) and are safe to include
#   unconditionally on any Debian-family node — nothing here requires the
#   caller to know which boot chain a given node uses.
#
#   `initramfs_provider` reports `'dracut'` on ZFSBootMenu nodes too (they
#   have dracut installed as a build dependency). That's intentional, not
#   an overlap to resolve: `boot::initramfs`'s `Exec['rebuild_initramfs']`
#   is a general "a kernel/driver config changed, refresh the initramfs"
#   hook other classes notify (e.g. e1000e driver params), independent of
#   `boot::zfsbootmenu`'s own `Exec['zfsbootmenu_build']`, which rebuilds
#   ZBM's own EFI image on version/config changes. Both are legitimate,
#   separate consumers of dracut on the same node.
#
#   `boot::refind` is explicitly ordered before `boot::zfsbootmenu`, since
#   the latter writes into rEFInd's directory structure.
#
# @example
#   include profile::platform::baseline::debian::boot
#
class profile::platform::baseline::debian::boot {
  include profile::platform::baseline::debian::boot::initramfs
  include profile::platform::baseline::debian::boot::refind
  include profile::platform::baseline::debian::boot::zfsbootmenu

  Class['profile::platform::baseline::debian::boot::refind']
  -> Class['profile::platform::baseline::debian::boot::zfsbootmenu']
}
