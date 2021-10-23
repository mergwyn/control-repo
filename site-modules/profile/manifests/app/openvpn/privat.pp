# @summary Set up openvpn client for privat VPN service
#
class profile::app::openvpn::privat(
  Boolean $use_systemd_resolved = lookup('defaults::vpn::use_systemd_resolved'),
){

  $service = 'openvpn-client@privat.service'

  $archive      = 'PrivateVPN-TUN'
  $archive_name = "${archive}.zip"
  $url          = "http://privatevpn.com/client/${archive_name}"
  $archive_path = "${facts['puppet_vardir']}/${archive_name}"
  $install_path = '/etc/openvpn/client'
  $creates      = "${install_path}/${archive}"
  archive { $archive_path:
    source       => $url,
    extract      => true,
    extract_path => $install_path,
    cleanup      => false,
    creates      => $creates,
  }

  file {'/etc/openvpn/client/privat.auth':
    require => Package['openvpn'],
    notify  => Service[$service],
    mode    => '0500',
    content => @("EOT"/),
               ${lookup('secrets::privatvpn::user')}
               ${lookup('secrets::privatvpn::password')}
               | EOT
  }

  if $use_systemd_resolved {
    package { 'openvpn-systemd-resolved': ensure => present }
    $require = Package[ 'openvpn-systemd-resolved', 'openvpn' ]
    $script = '/etc/openvpn/update-systemd-resolved'

  } else {
    package { 'openresolv': ensure => present, }
    $script = '/etc/openvpn/update-resolv-conf'
    $require = Package[ 'openvpn', 'openresolv' ]
  }

  file {'/etc/openvpn/client/privat.conf':
    require => $require,
    notify  => Service[$service],
    content => @("EOT"/),
               remote uk-lon.pvdata.host 1195 udp
               config  '/etc/openvpn/client/PrivateVPN-TUN/UDP/PrivateVPN-UK-London 1-TUN-1194.ovpn'
               comp-lzo no
               auth-user-pass '/etc/openvpn/client/privat.auth'
               script-security 2
               setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
               up ${script}
               up-restart
               down ${script}
               down-pre
               dhcp-option DOMAIN-ROUTE .
               | EOT
  }

  service { $service:
    ensure    => running,
    enable    => true,
    require   => Package['openvpn'],
    subscribe => Systemd::Dropin_file['openvpn-client-nproc.conf'],
  }

  firewalld_port {'Open port 1195 in the public Zone':
    ensure   => 'present',
    zone     => 'public',
    port     => 1195,
    protocol => 'udp',
  }
  firewalld_port {'Open port 1195 in the external Zone':
    ensure   => 'present',
    zone     => 'external',
    port     => 1195,
    protocol => 'udp',
  }

}
