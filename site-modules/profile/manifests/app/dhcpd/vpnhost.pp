#

define profile::app::dhcpd::vpnhost (
  Stdlib::MAC                      $mac     = undef,
  Optional[Stdlib::IP::Address::V4] $ip     = undef,
  Stdlib::IP::Address::V4          $gateway = lookup('defaults::vpn_gateway'),
  ) {

  dhcp::host { $title:
    mac     => $mac,
    ip      => $ip,
    options => {
      routers             => $gateway,
      domain-name-servers => $gateway,
    }
  }
}
