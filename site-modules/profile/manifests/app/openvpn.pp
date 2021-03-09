# @summary openvpn ttunnel
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

class profile::app::openvpn (
  String[1] $lan = $facts['networking']['primary'],
  String[1] $wan = 'eth1',
  String[1] $vpn = 'tun0',
) {

  $aptpackages = [
    'openvpn',
    'unzip',
    'ca-certificates',
  ]
  package { $aptpackages: ensure   => present, }

  $service = 'openvpn-client@.service'

  systemd::dropin_file { 'openvpn-client-nproc.conf':
    unit    => $service,
    content => @("EOT"/),
               [Service]
               LimitNPROC=infinity
               | EOT
  }
  file { "/etc/systemd/system/${service}.d/override.conf": ensure => absent, }

##### privat vpn setup
  include profile::app::openvpn::privat

# TODO install https://github.com/jonathanio/update-systemd-resolved

###### Firewall setup
  class {'firewalld':
    purge_direct_rules  => true,
    purge_direct_chains => true,
  }

  firewalld_zone { 'home':
    interfaces       => [$lan],
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
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
  }

# home zone services and ports
  firewalld_service {'Allow dns in the home Zone':
    ensure  => present,
    zone    => 'home',
    service => 'dns',
  }
  firewalld_service {'Allow http in the home Zone':
    ensure  => present,
    zone    => 'home',
    service => 'http',
  }
  firewalld_service {'Allow https in the home Zone':
    ensure  => present,
    zone    => 'home',
    service => 'https',
  }
  firewalld_service {'Allow ssh in the home Zone':
    ensure  => present,
    zone    => 'home',
    service => 'ssh',
  }
  firewalld_service {'Allow zabbix-agent in the home Zone':
    ensure  => present,
    zone    => 'home',
    service => 'zabbix-agent',
  }

# External zone services and ports
  firewalld_service {'Allow openvpn in the external Zone':
    ensure  => present,
    zone    => 'external',
    service => 'openvpn',
  }
  firewalld_service {'Allow http in the external Zone':
    ensure  => present,
    zone    => 'external',
    service => 'http',
  }
  firewalld_service {'Allow https in the external Zone':
    ensure  => present,
    zone    => 'external',
    service => 'https',
  }

# public zone services and ports
  firewalld_service {'Allow openvpn in the public Zone':
    ensure  => present,
    zone    => 'public',
    service => 'openvpn',
  }

  include profile::app::openvpn::forwards

###### unbound setup
#TODO unbound setup
#server:
#	interface: 10.58.0.3
#	access-control: 10.58.0.0/16 allow
#	Access-control: 127.0.0.0/8 allow
#	do-not-query-localhost: no
#	val-permissive-mode: yes
#forward-zone:
#	name: "."
#	forward-addr: 127.0.0.53


}
