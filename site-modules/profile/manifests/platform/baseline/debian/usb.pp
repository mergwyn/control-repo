# @summary usb automount settings
#

class profile::platform::baseline::debian::usb {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case $facts['virtual'] {
    'physical': {
      file {'/etc/udev/rules.d/11-media-by-label-auto-mount.rules':
        ensure => present,
        source => 'puppet:///modules/profile/11-media-by-label-auto-mount.rules',
      }
    }
    default: {
    }
  }

}
