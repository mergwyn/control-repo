# @summary Add A and PTR dns entries for host
#
# @param host
#   hostname to be added (without domain). Defaults to the title if undefined.
#
# @param ipaddress
#   ipv4 address (ipv6 not supported)
#
define profile::app::samba::dnsentry (
  Optional[Stdlib::Fqdn]  $host      = $name,
  Stdlib::IP::Address::V4 $ipaddress = undef,
) {
  $octets = split($ipaddress, '.')
# TODO can use join for this?
  $revzone = "${octets[2]}.${octets[1]}.${octets[0]}.in-addr.arpa"

  samba::dc::dnsentry { $host:
    zone   => $trusted['domain'],
    host   => $host,
    type   => 'A',
    record => $ipaddress,
  }
  samba::dc::dnsentry { "${host} rev":
    zone   => $revzone,
    host   => $octets[3],
    type   => 'PTR',
    record => "${host}.${trusted['domain']}"
  }
}
