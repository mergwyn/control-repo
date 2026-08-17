# @summary Configures time synchronisation using chrony.
#
# Physical hosts run chrony as an NTP server/client, including Samba AD
# signed-NTP support for Windows clients. Virtual/container nodes have
# chrony removed, since they sync time from their host.
#
# @param allow_subnets
#   Subnets permitted to query these hosts for time (e.g. AD clients).
#
class profile::platform::baseline::debian::ntp (
  Array[String] $allow_subnets = lookup('ntp::allow_subnets', Array[String], 'first', []),
) {
  if $facts['virtual'] != 'physical' {
    package { 'chrony': ensure => absent }
  }
  else {
    $network_servers = lookup('ntp::servers')

    # Ubuntu enables systemd-timesyncd by default; it must be disabled
    # so it doesn't fight with chrony over the system clock.
    service { 'systemd-timesyncd':
      ensure => stopped,
      enable => mask,
      before => Service['chrony'],
    }

    package { 'chrony':
      ensure => installed,
    }

    # The conf file is managed by this class as the voxpupuli/chronypPuppet
    # module doesn't expose ntpsigndsocket parameter yet.
    file { '/etc/chrony/chrony.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('profile/ntp/chrony.conf.epp', {
        'servers'        => $network_servers,
        'allow'          => $allow_subnets,
        'ntpsigndsocket' => '/var/lib/samba/ntp_signd/',
      }),
      require => Package['chrony'],
      notify  => Service['chrony'],
    }

    service { 'chrony':
      ensure  => running,
      enable  => true,
      require => Package['chrony'],
    }
  }
}
