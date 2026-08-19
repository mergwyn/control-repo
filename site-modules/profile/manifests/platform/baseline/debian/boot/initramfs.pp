# @summary Manage the general-purpose initramfs rebuild hook
#
# @description
# This class provides a unified interface for rebuilding initramfs on
# demand, for any config change that needs one - regardless of whether the
# node also runs ZFSBootMenu. dracut is genuinely in use on ZFSBootMenu
# nodes too (it's a build dependency there), so `initramfs_provider`
# reports `'dracut'` on them same as any other dracut-based node.
#
# This is deliberately independent of
# `profile::platform::baseline::debian::boot::zfsbootmenu`'s own
# `Exec['zfsbootmenu_build']`, which rebuilds ZBM's own EFI image via
# `make core dracut` when ZBM's version or config.yaml changes. That exec
# answers "has ZBM itself changed?"; `Exec['rebuild_initramfs']` here
# answers "has something on this system (kernel params, driver config,
# etc.) changed such that the initramfs content needs a refresh?" - e.g.
# a class managing e1000e driver options notifies this exec directly.
# Both legitimately run `dracut -f` on the same node for different reasons.
#
# It abstracts the underlying initramfs implementation and ensures that:
#
# * dracut is used where a node's fact selects it (any dracut-based system,
#   including ZFSBootMenu nodes)
# * initramfs-tools is supported for legacy Debian systems
# * no action is taken on container platforms (e.g. LXC), via the `none`
#   provider
#
# A single rebuild command is exposed:
#   /usr/local/sbin/rebuild-initramfs
#
# Other classes needing an initramfs refresh should notify:
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
#     - 'dracut'            : Use dracut to generate initramfs (any
#                              dracut-based system, including ZFSBootMenu
#                              nodes)
#     - 'initramfs-tools'   : Use Debian initramfs-tools
#     - 'none'              : No initramfs (containers)
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
