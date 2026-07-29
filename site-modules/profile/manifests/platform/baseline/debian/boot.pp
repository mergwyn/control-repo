# @summary
#   Entry point for boot-related configuration on Debian-family physical nodes.
#
# Includes sub-classes managing boot loader and boot manager configuration.
# Currently covers rEFInd; intended to be extended with further boot-related
# baseline config (e.g. ZFSBootMenu specifics) as needed.
class platform::baseline::debian::boot {
  include platform::baseline::debian::boot::refind
}
