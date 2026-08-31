#
class role::vpn_gateway {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::wireguard
  include profile::app::unbound::wireguard

  Class['profile::platform::baseline']
  -> Class['profile::app::wireguard']
  -> Class['profile::app::unbound::wireguard']
}
