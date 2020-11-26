# @summary baseline profile applied to all hosts

class profile::platform::baseline (
  Boolean $puppet_agent  = true,
  Boolean $enable_monitoring = false,
){

  # OS Specific
  case $facts['os']['family']{
    'Debian':   {
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
  include profile::platform::baseline::packages

}
