#

class profile::app::openvpn::privat {

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
    content => @("EOT"/),
               ${lookup('secrets::privatvpn::user')}
               ${lookup('secrets::privatvpn::password')}
               | EOT
  }
  file {'/etc/openvpn/client/privat.conf':
    require => Package['openvpn'],
    notify  => Service[$service],
    content => @("EOT"/),
               remote uk-lon.pvdata.host 1195 udp
               config  '/etc/openvpn/client/PrivateVPN-TUN/UDP/PrivateVPN-UK-London 1-TUN-1194.ovpn'
               comp-lzo no
               auth-user-pass '/etc/openvpn/client/privat.auth'
               config '/etc/openvpn/scripts/update-systemd-resolved.conf'
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
