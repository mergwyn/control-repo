#

class profile::network::dhcpd (
  Optional[Enum['primary','secondary']] $role         = undef,
  Optional[Stdlib::IP::Address]         $peer_address = undef,
  ) {
  $owner = 'dhcpd'
  $group = 'dhcpd'
  $perms = "${owner}.${group}"
  $keytab = '/etc/dhcp/dhcpd.keytab'


  # Core dhcpd configuration
  $domain = $trusted['domain']

  class { 'dhcp':
    interfaces         => [ $facts['networking']['primary'] ],
    nameservers        => [ '192.168.11.22', '192.168.11.21' ],
    ntpservers         => [ "foxtrot.${domain}", "golf.${domain}" ],
    default_lease_time => 14400,
    extra_config       => [ 'include "/etc/dhcp/dhcpd.samba_ddns";' ],
  }
  dhcp::pool { $domain:
    network  => '192.168.11.0',
    mask     => '255.255.255.0',
    range    => '192.168.11.100 192.168.11.199',
    gateway  => '192.168.11.254',
    failover => 'dhcp-failover',
  }
  if ($role and $peer_address) {
    class { 'dhcp::failover':
      role         => $role,
      peer_address => $peer_address,
      port         => 647,
      mclt         => 3600,
    }
  }

  # Hosts with fixed ip
  dhcp::host { 'switch1': mac => '00:8e:f2:59:c7:98', ip => '192.168.11.1', }
  dhcp::host { 'switch2': mac => 'a0:40:a0:71:7e:ce', ip => '192.168.11.2', }
  dhcp::host { 'papa':    mac => '00:16:3e:fc:2a:87', ip => '192.168.11.240', }
  dhcp::host { 'romeo':   mac => '00:16:3e:fb:dc:5e', ip => '192.168.11.250', }
  dhcp::host { 'yankee':  mac => '00:16:3e:97:62:2b', ip => '192.168.11.251', }

  # Hosts with different gateway (VPN)
  dhcp::host { 'LGwebOSTV':
    mac     => '7c:1c:4e:48:06:e2',
    options => { routers => '192.168.11.250' }
  }
  dhcp::host { 'india':
    mac     => '00:16:3e:93:c6:21',
    ip      => '192.168.11.41',
    options => { routers => '192.168.11.251' }
  }
  dhcp::host { 'tango':
    mac     => '00:16:3e:01:f8:9a',
    options => { routers => '192.168.11.250' }
  }

  # Hosts that just need names,
  dhcp::host { 'DELLA3F95F':            mac => '08:00:37:a3:f9:5f' }
  dhcp::host { 's685ip':                mac => '00:01:e3:9a:f9:c1' }
  dhcp::host { 'humax':                 mac => '80:1f:02:21:a1:74' }
  dhcp::host { 'lounge-sonos-playbar':  mac => '00:0e:58:bc:b4:dc' }
  dhcp::host { 'lounge-sonos-play1-ls': mac => '00:0e:58:c9:f0:9a' }
  dhcp::host { 'lounge-sonos-play1-rs': mac => '94:9F:3E:12:FA:8A' }
  dhcp::host { 'kitchen-sonos-playone': mac => '78:28:CA:CB:8B:94' }

  # export keytab to allow script to run
  exec { 'chown_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    onlyif  => "stat -c '%U.%G' ${keytab} | grep -v ${perms}",
    command => "chown ${perms} ${keytab}",
  }
  exec { 'export_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => '/etc/dhcp/dhcpd.keytab',
    command => "samba-tool domain exportkeytab \
		${keytab} --principal=dhcp",
    notify  => Exec['chown_dhcp_keytab'],
  }

  # config files
  file { '/etc/dhcp/dhcpd.samba_ddns':
    ensure  => file,
    require => Package['isc-dhcp-server'],
    notify  => Service['isc-dhcp-server'],
    source  => 'puppet:///modules/profile/dhcp/dhcpd.samba_ddns',
    owner   => $owner,
    group   => $group,
  }
  file { "/etc/dhcp/dhcpd.${::domain}": ensure  => absent, }
  #Concat::Fragment dhcp_hosts <<| tag == "vpn"|>>

  file { '/etc/dhcp/dhcpd-update-samba-dns.conf':
    ensure => file,
    owner  => $owner,
    group  => $group,
    source => 'puppet:///modules/profile/dhcp/dhcpd-update-samba-dns.conf',
  }

  file { '/etc/dhcp/dhcpd-update-samba-dns.sh':
    ensure => file,
    mode   => '0755',
    owner  => $owner,
    group  => $group,
    source => 'puppet:///modules/profile/dhcp/dhcpd-update-samba-dns.sh',
  }

  file { '/etc/dhcp/samba-dnsupdate.sh':
    ensure => file,
    mode   => '0755',
    owner  => $owner,
    group  => $group,
    source => 'puppet:///modules/profile/dhcp/samba-dnsupdate.sh',
  }

  # need to make sure apparmor is updated to allow the scripts to fire
  include profile::platform::baseline::debian::apparmor
  file { '/etc/apparmor.d/local/usr.sbin.dhcpd':
    ensure  => file,
    notify  => Service['apparmor'],
    content => "  /etc/dhcp/dhcpd-update-samba-dns.sh krwux, \n",
    owner   => 'root',
    group   => 'root',
  }

}
