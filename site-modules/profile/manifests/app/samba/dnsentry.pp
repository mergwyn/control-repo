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
  $bits = lookup('defaults::bits')
  case $bits {
    '8':     { # Type A
      $revzone = "${octet[0]}.in-addr.arpa"
      $ptr_ip = "${octet[3]}.${octet[2]}.${octet[1]}"
    }
    '16':    { # Type A
      $revzone = "${octet[1]}.${octet[0]}.in-addr.arpa"
      $ptr_ip = "${octet[3]}.${octet[2]}"
    }
    '24':    { # Type C
      $revzone = "${octet[2]}.${octet[1]}.${octet[0]}.in-addr.arpa"
      $ptr_ip = $octet[3]
    }
    default: { fail("Can't create reverse domain with ${bits} bits") }
  }

  notify {"A: ${ipaddress}, PTR: ${ptr_ip}, Zone: ${revzone}, split: ${octet}":
    loglevel => debug,
    withpath => true,
  }

  samba::dc::dnsentry { $host:
    zone   => $trusted['domain'],
    host   => $host,
    type   => 'A',
    record => $ipaddress,
  }
  samba::dc::dnsentry { "${host} rev":
    zone   => $revzone,
    host   => $ptr_ip,
    type   => 'PTR',
    record => "${host}.${trusted['domain']}"
  }
}
