# @summary ntp settings
#
class profile::platform::baseline::debian::ntp
{

# ntp for physical machines only
  if $facts['virtual'] != 'physical' {
    package { 'ntp': ensure => absent }
  }
  else {
    $local_clock = '127.127.1.0'
    #$network_servers = $servers + lookup('ntp::servers'),
    $network_servers = lookup('ntp::servers')

    $restrict_default = [
      'default kod nomodify notrap nopeer mssntp',
      $local_clock,
    ]

    $restrict_args = ' mask 255.255.255.255 nomodify notrap nopeer noquery'
    $restrict = regsubst($network_servers, '$', $restrict_args)

    class { 'ntp':
      ntpsigndsocket    => '/var/lib/samba/ntp_signd/',
      preferred_servers => $network_servers,
      servers           => [ $local_clock ] + $network_servers,
      restrict          => $restrict_default + $restrict,
      fudge             => [ "${local_clock} stratum 10" ],
    }
  }
}
