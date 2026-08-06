# @summary
#   Manages the rEFInd boot manager menu timeout on physical nodes.
#
# Sets a consistent rEFInd menu timeout across all physical hosts running
# rEFInd as their boot manager. Hosts without rEFInd installed are skipped
# automatically via the has_refind custom fact, so this class is safe to
# include broadly (e.g. from a common physical-node baseline) without
# needing to maintain a manual list of applicable nodes.
#
# Note: this manages rEFInd's own menu timeout only (set in refind.conf).
# It does not manage the separate UEFI firmware-level boot timeout
# (visible via `efibootmgr`), which is not reliably manageable from the
# OS on all hardware and is set manually where needed.
#
# @param timeout
#   Timeout in seconds for the rEFInd boot menu before it auto-boots the
#   default entry. Defaults to 5 seconds, chosen as a balance between
#   giving enough time to intervene and not slowing routine reboots.
#
# @example Basic usage with default timeout
#   include profile::platform::baseline::debian::boot::refind
#
# @example Overriding the timeout via Hiera
#   profile::platform::baseline::debian::boot::refind::timeout: 10
class profile::platform::baseline::debian::boot::refind (
  Integer $timeout = 5,
) {
  if $facts['has_refind'] {
    file_line { 'refind_timeout':
      path  => '/boot/efi/EFI/refind/refind.conf',
      line  => "timeout ${timeout}",
      match => '^timeout\s',
    }

    file { '/boot/efi/EFI/BOOT':
      ensure => directory,
    }

    # Copy rEFInd itself into the standard UEFI fallback path, so
    # firmware can find and boot it even if NVRAM entries are lost.
    # Uses a local file:// source since this is copying within the
    # same node, not distributing from the Puppet server.
    file { '/boot/efi/EFI/BOOT/BOOTX64.EFI':
      ensure  => file,
      source  => 'file:///boot/efi/EFI/refind/refind_x64.efi',
      require => File['/boot/efi/EFI/BOOT'],
    }
  } else {
    notify { 'refind_not_present':
      message => "platform::baseline::debian::boot::refind: skipped, no refind.conf found on ${trusted['certname']}",
    }
  }
}
