#
class role::mac_laptop {
  include profile::platform::baseline
  include profile::mac::managedmac
}
