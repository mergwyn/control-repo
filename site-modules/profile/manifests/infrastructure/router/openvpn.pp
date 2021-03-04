#

class profile::infrastructure::router::openvpn {

  $aptpackages = [
    'openvpn',
    'unzip',
    'ca-certificates',
  ]
  package { $aptpackages: ensure   => present, }

# Common firewall settings for vpn
  firewalld_zone {'public':
    interfaces => ['tun0'],
  }

  firewalld_service {'Allow openvpn in the public Zone':
    ensure  => present,
    zone    => 'public',
    service => 'openvpn',
  }

  # TODO install https://github.com/jonathanio/update-systemd-resolved

}
