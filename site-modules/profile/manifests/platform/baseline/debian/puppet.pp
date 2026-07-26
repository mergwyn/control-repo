class profile::platform::baseline::debian::puppet {
  service { 'puppet':
    ensure => running,
    enable => true,
  }
}
