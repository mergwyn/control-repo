# @summary
#   True if ZFSBootMenu's generate-zbm command is available on this node,
#   indicating ZBM is installed and images can be regenerated.
#
# Used as a guard in platform::baseline::debian::boot::zbm_regen so that
# class can be included broadly across physical nodes without needing
# a manually maintained list of which hosts currently run ZBM.
Facter.add(:has_zfsbootmenu) do
  setcode do
    !!Facter::Core::Execution.which('generate-zbm')
  end
end
