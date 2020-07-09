# @summary Wrapper for ntp support

class profile::platform::baseline::debian::ntp (
  Optional[Array[String]] $servers = lookup('defaults::time_servers')
  ) {

  $local_clock = '127.127.1.0'
  $network_servers = $servers + lookup('ntp::servers')

# Build array for restrict using the combined network_servers array
  $restrict = [
    'default kod nomodify notrap nopeer mssntp',
    $local_clock,
  ]

  $network_servers.each |String $server| {
    $restrict = $restrict + [ "${server}   mask 255.255.255.255    nomodify notrap nopeer noquery" ]
  }

  class { 'ntp':
    ntpsigndsocket    => '/var/lib/samba/ntp_signd/',
    servers           => [ $local_clock ] + $network_servers,
    preferred_servers => $servers,
    burst             => true,
    fudge             => [ "${local_clock} stratum 10" ],
    restrict          => $restrict,
  }
}
