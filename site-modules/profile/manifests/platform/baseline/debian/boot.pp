# @summary
#   Entry point for boot-related configuration on Debian-family physical nodes.
#
# Includes sub-classes managing boot loader and boot manager configuration.
# Currently covers rEFInd; intended to be extended with further boot-related
# baseline config (e.g. ZFSBootMenu specifics) as needed.
class profile::platform::baseline::debian::boot {
  include profile::platform::baseline::debian::boot::refind
  include profile::platform::baseline::debian::boot::zfsbootmenu
  include profile::platform::baseline::debian::boot::initramfs
  include profile::platform::baseline::debian::boot::dracut
}
