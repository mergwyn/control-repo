# @summary Manage initramfs generation for non-ZFSBootMenu Debian systems
#
# @description
# This class provides a unified interface for rebuilding initramfs across
# heterogeneous environments (physical hosts, VMs, and containers) that are
# NOT using ZFSBootMenu.
#
# Nodes with `has_zfsbootmenu` true manage their own dracut build entirely
# through `profile::platform::baseline::debian::boot::zfsbootmenu` (and its
# private `dracut_setup` sub-class) and should NOT be routed through this
# class's `dracut` provider - doing so sets up two independent things
# rebuilding the same initramfs. The `initramfs_provider` fact should report
# `'none'` on ZFSBootMenu nodes; see the guard rail in `boot.pp`.
#
# This class abstracts the underlying initramfs implementation for
# everything else and ensures that:
#
# * dracut is used where a node's fact selects it (non-ZBM dracut systems)
# * initramfs-tools is supported for legacy Debian systems
# * no action is taken on container platforms (e.g. LXC), via the `none`
#   provider
#
# A single rebuild command is exposed:
#   /usr/local/sbin/rebuild-initramfs
#
# Other classes (outside of ZFSBootMenu, which manages its own rebuild)
# should notify:
#   Exec['rebuild_initramfs']
#
# This avoids hardcoding initramfs tooling throughout the codebase and
# prevents silent failures when the wrong tool is invoked.
#
# @example
#   include profile::platform::baseline::debian::boot::initramfs
#
# @example Specify provider via Hiera
#   profile::platform::baseline::debian::boot::initramfs::provider: dracut
#
# @param provider
#   The initramfs implementation to use.
#
#   Valid values:
#     - 'dracut'            : Use dracut to generate initramfs (non-ZBM systems)
#     - 'initramfs-tools'   : Use Debian initramfs-tools
#     - 'none'              : No initramfs (containers, and ZFSBootMenu nodes
#                              which manage dracut themselves)
#
class profile::platform::baseline::debian::boot::initramfs (
  Enum['dracut', 'initramfs-tools', 'none', 'unknown'] $provider = $facts['initramfs_provider'],
) {
  $content = $provider ? {
    'dracut' => @("EOF"/L)
  #!/bin/sh
  set -e
  echo "Rebuilding initramfs using dracut"
  exec dracut -f
  EOF
  ,
    'initramfs-tools' => @("EOF"/L)
  #!/bin/sh
  set -e
  echo "Rebuilding initramfs using initramfs-tools"
  exec /usr/sbin/update-initramfs -u -k all
  EOF
  ,
    default => @("EOF"/L)
  #!/bin/sh
  echo "No initramfs provider on this system"
  exit 0
  EOF
  ,
  }

  file { '/usr/local/sbin/rebuild-initramfs':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => $content,
  }

  exec { 'rebuild_initramfs':
    command     => '/usr/local/sbin/rebuild-initramfs',
    path        => ['/usr/local/sbin', '/usr/bin', '/usr/sbin', '/bin'],
    refreshonly => true,
  }
}
