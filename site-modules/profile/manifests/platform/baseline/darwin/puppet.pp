class profile::platform::baseline::darwin {
  service { 'puppet':
    ensure => running,
    enable => true,
  }
}
