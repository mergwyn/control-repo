# vim: sw=2:ai:nu expandtab

class role::mac_laptop {
  include profile::managedmac
  include profile::brew
}
