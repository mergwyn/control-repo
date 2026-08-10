# @summary
#   Sets the initramfs update provider depending on availability of
#   executables.
#
# ZFSBootMenu nodes are checked for before the generic dracut-binary check:
# ZBM installs dracut as a build dependency (see
# profile::platform::baseline::debian::boot::zfsbootmenu::dracut_setup), so
# checking for /usr/bin/dracut first would always report 'dracut' on ZBM
# nodes too, even though ZBM manages its own dracut build independently of
# profile::platform::baseline::debian::boot::initramfs. Reporting 'none'
# here on ZBM nodes means that class's dracut path is a true no-op on them,
# rather than a second, uncoordinated thing rebuilding the same initramfs.
Facter.add(:initramfs_provider) do
  setcode do
    if File.exist?('/run/systemd/container')
      'none'
    elsif Facter::Core::Execution.which('generate-zbm')
      'none'
    elsif File.exist?('/usr/bin/dracut')
      'dracut'
    elsif File.exist?('/usr/sbin/update-initramfs')
      'initramfs-tools'
    else
      'unknown'
    end
  end
end
