# @summary sysctl settings
#

class profile::platform::baseline::debian::sysctl {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case $facts['virtual'] {
    'physical': {
      sysctl{ 'vm.swappiness':  ensure => present, value => '1', }
      sysctl{ 'vm.dirty_ratio': ensure => present, value => '15', }
    }
    default: {
    }
  }

}
