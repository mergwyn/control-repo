# @summary
#   Sets the initramfs update provider depending on availability of
#   executables.
#
# Reports 'dracut' whenever the dracut binary is present, including on
# ZFSBootMenu nodes. This is intentional: profile::platform::baseline::
# debian::boot::initramfs's Exec['rebuild_initramfs'] is a general-purpose
# "a kernel/driver config file changed, refresh the initramfs" hook that
# other classes notify (e.g. e1000e driver params) - it's independent of
# profile::platform::baseline::debian::boot::zfsbootmenu's own
# Exec['zfsbootmenu_build'], which rebuilds ZBM's own EFI image via
# `make core dracut` when ZBM's version or config changes. Both are
# legitimate, separate consumers of dracut on the same node.
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
