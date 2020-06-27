#

class profile::platform::baseline (
  Boolean $puppet_agent  = true,
  Array   $timeservers = ['0.pool.ntp.org','1.pool.ntp.org'],
  Boolean $enable_monitoring = false,
){

  # Global
  #class {'::time':
  #  servers => $timeservers,
  #}


  # OS Specific
  case $facts['os']['family']{
    'Debian':   {
# TODO Make puppet agent cross platform
      include ::profile::puppet::agent
      include ::profile::platform::baseline::debian
    }
    'Darwin':   {
      include ::profile::platform::baseline::darwin
    }
    'windows': {
      include ::profile::platform::baseline::windows
    }
    default: {
      fail('Unsupported operating system!')
    }
  }

}
