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
#   `initramfs_provider` reports `'none'` on any node where ZFSBootMenu is
#   present (see lib/facter/initramfs_provider.rb), so `boot::initramfs`'s
#   dracut path and `boot::zfsbootmenu`'s own dracut build never overlap -
#   this is enforced at the fact level, not re-checked here.
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
