#

class profile::router::nordvpn {

# Install software
  exec { 'apt-get-update':
    command     => '/usr/bin/apt-get update',
    refreshonly => true,
  }
  $version = 'nordvpn-release_1.0.0_all.deb'
  $repo = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/${version}"
  $source = "/opt/puppetlabs/puppet/cache/${version}"
  archive {$source:
    ensure => present,
    source => $repo,
    notify => Exec['apt-get-update'],
  }

  $aptpackages = [
    'net-tools',
    'traceroute',
    'nordvpn',
  ]
  package { $aptpackages: ensure   => present, }


# Setup nord
#nordvpn login
#nordvpn connect
#nordvpn whitelist add subnet 192.168.11.0/24
#nordvpn set technology NordLynx
#nordvpn set autoconnect enabled

# Configure firewall
#iin=eth0
#out=tun0
#sudo "echo 1 > /proc/sys/net/ipv4/ip_forward"
#sudo iptables -t nat -A POSTROUTING -o "${out}" -j MASQUERADE
#sudo iptables -A FORWARD -i "${in}" -o "${out}" -m state --state RELATED,ESTABLISHED -j ACCEPT
#sudo iptables -A FORWARD -i "${out}" -o "${in}" -j ACCEPT

}
