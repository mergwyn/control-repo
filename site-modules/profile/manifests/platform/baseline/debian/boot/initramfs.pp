# @summary Manage initramfs generation consistently across platforms
#
# @description
# This class provides a unified interface for rebuilding initramfs across
# heterogeneous environments (physical hosts, VMs, and containers).
#
# It abstracts the underlying initramfs implementation and ensures that:
#
# * dracut is used on modern ZFSBootMenu systems
# * initramfs-tools is supported for legacy Debian systems
# * no action is taken on container platforms (e.g. LXC)
#
# A single rebuild command is exposed:
#   /usr/local/sbin/rebuild-initramfs
#
# Other classes should notify:
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
#     - 'dracut'            : Use dracut to generate initramfs (preferred for ZBM)
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
