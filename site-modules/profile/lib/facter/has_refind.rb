# @summary
#   True if this node has a rEFInd configuration file present, indicating
#   rEFInd is installed and in use as the boot manager.
#
# Used as a guard in platform::baseline::debian::boot::refind so that
# class can be included broadly across physical nodes without needing
# a manually maintained list of which hosts currently run rEFInd.
Facter.add(:has_refind) do
  setcode do
    File.exist?('/boot/efi/EFI/refind/refind.conf')
  end
end
