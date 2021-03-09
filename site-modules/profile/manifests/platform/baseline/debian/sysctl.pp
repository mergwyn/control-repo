# @summary sysctl settings
#

class profile::platform::baseline::debian::sysctl (
  Integer $disable_ipv6 = 1
) {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case $facts['virtual'] {
    'physical': {
      sysctl{ 'vm.swappiness':                      ensure => present, value => '1', }
      sysctl{ 'vm.dirty_ratio':                     ensure => present, value => '15', }
      sysctl{ 'net.ipv6.conf.all.disable_ipv6':     ensure => present, value => $disable_ipv6, }
      sysctl{ 'net.ipv6.conf.default.disable_ipv6': ensure => present, value => $disable_ipv6, }
      sysctl{ 'net.ipv6.conf.lo.disable_ipv6':      ensure => present, value => $disable_ipv6, }
    }
    default: {
    }
  }

}
