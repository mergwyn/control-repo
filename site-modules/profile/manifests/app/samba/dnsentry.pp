# @summary Add A and PTR dns entries for host
#
# @param host
#   hostname to be added (without domain). Defaults to the title if undefined.
#
# @param ipaddress
#   ipv4 address (ipv6 not supported)
#
define profile::app::samba::dnsentry (
  Stdlib::Fqdn            $host      = $title,
  Stdlib::IP::Address::V4 $ipaddress = undef,
) {
  $octet = split($ipaddress, '\.')
# TODO can use join for this?
  $revzone = "${octet[2]}.${octet[1]}.${octet[0]}.in-addr.arpa"
#
  notify {"ipaddress is ${ipaddress}, split is ${octet}":
    loglevel => debug,
    withpath => true,
  }
#
  samba::dc::dnsentry { $host:
    zone   => $trusted['domain'],
    host   => $host,
    type   => 'A',
    record => $ipaddress,
  }
  samba::dc::dnsentry { "${host} rev":
    zone   => $revzone,
    host   => $octet[3],
    type   => 'PTR',
    record => "${host}.${trusted['domain']}"
  }
}
