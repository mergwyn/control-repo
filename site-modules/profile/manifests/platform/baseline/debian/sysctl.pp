# @summary sysctl settings
#

class profile::platform::baseline::debian::sysctl {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case $facts['virtual'] {
    'physical': {
      include sysctl
      sysctl::configuration { 'vm.swappiness':  value => '1', }
      sysctl::configuration { 'vm.dirty_ratio': value => '15', }
    }
    default: {
    }
  }

}
