# @summary
#   Sets the initramfs update provider depending on availablity of
#   of executables
Facter.add(:initramfs_provider) do
  setcode do
    if File.exist?('/run/systemd/container')
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
