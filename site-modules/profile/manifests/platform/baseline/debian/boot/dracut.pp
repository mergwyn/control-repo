# @summary Configure dracut for ZFS and kernel updates
#
# @description
# Configures dracut for systems using OpenZFS with ZFSBootMenu.
#
# This class:
#
# * Ensures the ZFS dracut module is available
# * Includes /etc/hostid inside generated initramfs images
# * Provides a common rebuild trigger
#
# This replaces direct use of update-initramfs on systems using dracut.
#
# Containers and systems without dracut should not include this class.
#
# @example
#   include profile::platform::baseline::debian::boot::dracut
#
class profile::platform::baseline::debian::boot::dracut {
  package { [
    'dracut',
    'zfs-dracut',
  ]:
    ensure => installed,
  }

  file { '/etc/dracut.conf.d/99-zfsbootmenu.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("EOF"/L),
      install_items+=" /etc/hostid "
      force_dracutmodules+=" zfs "
      hostonly="no"
      | EOF
  }
}
