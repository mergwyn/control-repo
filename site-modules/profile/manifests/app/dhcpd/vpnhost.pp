#

define profile::app::dhcpd::vpnhost (
  Stdlib::MAC             $mac     = undef,
  Stdlib::IP::Address::V4 $gateway = '192.168.11.251'
  ) {

  dhcp::host { $title:
    mac     => $mac,
    options => {
      routers             => $gateway,
      domain-name-servers => $gateway,
    }
  }
}
