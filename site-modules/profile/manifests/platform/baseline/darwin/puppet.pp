class profile::platform::baseline::darwin::puppet {
  service { 'puppet':
    ensure => running,
    enable => true,
  }
}
