#

define profile::app::dhcpd::vpnhost (
  Stdlib::MAC                      $mac     = undef,
  Optional[Stdlib::IP::Address::V4] $ip      = undef,
  Stdlib::IP::Address::V4          $gateway = '192.168.11.251'
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
