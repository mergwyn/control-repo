# @summary openvpn tunnel
#
# In order from least trusted to most trusted, the predefined zones within firewalld are:
#
# * drop:
#   The lowest level of trust. All incoming connections are dropped
#   without reply and only outgoing connections are possible.
# * block:
#   Similar to the above, but instead of simply dropping connections,
#   incoming requests are rejected with an icmp-host-prohibited or
#   icmp6-adm-prohibited message.
# * public:
#   Represents public, untrusted networks. You don’t trust other
#   computers but may allow selected incoming connections on a
#   case-by-case basis.
# * external:
#   External networks in the event that you are using the firewall as
#   your gateway. It is configured for NAT masquerading so that your
#   internal network remains private but reachable.
# * internal:
#   The other side of the external zone, used for the internal portion of
#   a gateway. The computers are fairly trustworthy and some additional
#   services are available.
# * dmz:
#   Used for computers located in a DMZ (isolated computers that will
#   not have access to the rest of your network). Only certain incoming
#   connections are allowed.
# * work:
#   Used for work machines. Trust most of the computers in the network.
#   A few more services might be allowed.
# * home:
#   A home environment. It generally implies that you trust most of the
#   other computers and that a few more services will be accepted.
# * trusted:
#   Trust all of the machines in the network. The most open of the
#   available options and should be used sparingly.
#
class profile::app::openvpn (
  String[1] $lan = 'eth0',
  String[1] $wan = 'eth1',
  String[1] $vpn = 'tun0',
  Boolean   $use_systemd_resolved = lookup('defaults::vpn::use_systemd_resolved'),
) {

  $scripts = '/etc/openvpn/scripts'

  $aptpackages = [
    'openvpn',
    'unzip',
    'ca-certificates',
  ]
  package { $aptpackages: ensure => present, }

  $service = 'openvpn-client@.service'

  systemd::dropin_file { 'openvpn-client-nproc.conf':
    unit    => $service,
    content => @("EOT"/),
               [Service]
               LimitNPROC=infinity
               | EOT
  }

##### privat vpn setup
  include profile::app::openvpn::privat

  include profile::app::unbound

# Remove https://github.com/jonathanio/update-systemd-resolved
  $tidylist= [
    '/opt/update-systemd-resolved',
    "${scripts}/update-systemd-resolved",
    "${scripts}/update-systemd-resolved.conf",
  ]
  file { $tidylist:
    ensure  => absent,
    recurse => true,
    force   => true,
  }

# dnsleak
  file { $scripts: ensure => directory, }

  file { "${scripts}/dnsleaktest":
    ensure  => file,
    require => File[ $scripts ],
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/profile/dnsleaktest',
  }

###### Firewall setup
  class {'firewalld':
    purge_direct_rules        => true,
    purge_direct_chains       => true,
    purge_direct_passthroughs => true,
    purge_unknown_ipsets      => true,
  }

  firewalld_zone { 'home':
    interfaces       => [$lan],
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
    masquerade       => true,
  }
  firewalld_zone { 'public':
    interfaces       => [$wan],
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
  }
  firewalld_zone { 'external':
    interfaces       => [$vpn],
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
    masquerade       => true,
  }

# home zone services and ports
  [ 'dns', 'http', 'https', 'ssh', 'zabbix-agent' ].each |String $service| {
    firewalld_service {"Allow ${service} in the home Zone":
      ensure  => present,
      zone    => 'home',
      service => $service,
    }
  }

  [ 'vrrp' ].each |String $protocol| {
    firewalld_rich_rule { "Accept ${protocol} in the home zone":
      ensure   => present,
      zone     => 'home',
      protocol => $protocol,
      action   => 'accept',
    }
  }

# External zone services and ports
  [ 'openvpn', 'http', 'https' ].each |String $service| {
    firewalld_service {"Allow ${service} in the external Zone":
      ensure  => present,
      zone    => 'external',
      service => $service,
    }
  }

# public zone services and ports
  [ 'openvpn' ].each |String $service| {
    firewalld_service {"Allow ${service} in the public Zone":
      ensure  => present,
      zone    => 'public',
      service => $service,
    }
  }

  include profile::app::openvpn::forwards

}
