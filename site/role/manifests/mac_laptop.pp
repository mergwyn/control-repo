# vim: sw=2:ai:nu expandtab

class role::mac_laptop {
  include profile::mac::managedmac
  include profile::mac::brew
  include profile::mac::munki_client
}
