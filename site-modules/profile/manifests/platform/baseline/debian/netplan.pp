# @summary netplan settings

class profile::platform::baseline::debian::netplan (
  Optional[Hash] $ethernets = { $facts['networking']['primary'] => { dhcp4 => true } },
  Optional[Hash] $bridges   = undef,
) {

  if $facts['os']['name'] != 'Ubuntu' {
    fail("${name} can only be called on Ubuntu")
  }

  package { 'netplan.io': }
  class { 'netplan':
    version   => 2,
    renderer  => 'networkd',
    ethernets => $ethernets,
    bridges   => $bridges,
  }
}
