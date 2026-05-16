#
class role::vpn_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::wireguard
}
