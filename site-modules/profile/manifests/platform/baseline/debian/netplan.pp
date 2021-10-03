# @summary netplan settings
#
# @param ethernets
#
# netplan module compliant hash specifying the ethernets
#
# @param bridges
#
# netplan module compliant hash specifying the bridges
#
#
class profile::platform::baseline::debian::netplan (
  Optional[Hash] $ethernets = { $facts['networking']['primary'] => { dhcp4 => true } },
  Optional[Hash] $bridges   = undef,
  Optional[Hash] $bonds   = undef,
  Optional[Hash] $vlans   = undef,
) {

  if $facts['os']['name'] != 'Ubuntu' {
    fail("${name} can only be called on Ubuntu")
  }

  package { 'netplan.io': }

  service { 'systemd-networkd':
    enable => true,
    start  => true,
  }

  class { 'netplan':
    version   => 2,
    renderer  => networkd,
    ethernets => $ethernets,
    bridges   => $bridges,
    bonds     => $bonds,
    vlans     => $vlans,
  }

  package { 'ifupdown': ensure => absent }

}
