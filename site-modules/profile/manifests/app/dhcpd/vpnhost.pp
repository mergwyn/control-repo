#

define profile::app::dhcpd::vpnhost (
  Stdlib::MAC                    $mac         = undef,
  Array[Stdlib::IP::Address::V4] $router      = '192.168.11.251',
  Array[Stdlib::IP::Address::V4] $nameservers = '192.168.11.251',
  ) {

  dhcp::host { $title:
    mac     => $mac,
    options => {
      routers             => $router ,
      domain-name-servers => $nameservers,
    }
  }
}
