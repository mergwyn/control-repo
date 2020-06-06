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

  class {'::profile::puppet::agent':
    #ensure => $puppet_agent,
  }

  # add zabbix client
  if $enable_monitoring {
    include ::profile::zabbix::agent
  }

  # OS Specific
  case $::kernel {
    'Linux':   {
      include ::profile::platform::baseline::linux
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
