#
#
class profile::app::dhcp (
  Boolean $dhcp4 = true,
  Optional[Enum['primary','secondary']] $role = undef,
  Optional[Stdlib::IP::Address::V4] $peer_address = undef,
) {
  if !$dhcp4 {
    notify { 'DHCPv4 disabled on this node': }
    return()
  }

  $keytab_path = '/etc/kea/dhcp.keytab'
  $realm       = upcase($trusted['domain'])
  $principal   = "dhcp-dns@${realm}"

  # ---- Keytab ----
  # declared in the kea module
  #file { '/etc/kea':
  #  ensure => directory,
  #  owner  => 'kea',
  #  group  => 'kea',
  #  mode   => '0750',
  #}

  exec { 'export-kea-ddns-keytab':
    creates => $keytab_path,
    command => "/usr/bin/samba-tool domain exportkeytab ${keytab_path} --principal=dhcp-dns",
    require => File['/etc/kea'],
  }

  file { $keytab_path:
    owner => 'kea',
    group => 'kea',
    mode  => '0400',
  }

  class { 'kea':
    manage_repo => true,
  }

# class { 'kea::dhcp4': }
# class { 'kea::dhcp_ddns': }
}
