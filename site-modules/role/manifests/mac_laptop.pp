#
class role::mac_laptop {
  include profile::platform::baseline
  #include profile::platform::baseline::darwin::managedmac

  include profile::app::unison
  include profile::app::k8s_tools
}
