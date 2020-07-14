# @summary Timexzne settings

class profile::platform::baseline::debian::timezone {

  class { 'timezone':
    timezone => 'Europe/London',
  }
}
