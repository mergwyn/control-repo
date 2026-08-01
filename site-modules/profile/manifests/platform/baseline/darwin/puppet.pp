class profile::platform::baseline::darwin::puppet {
  service { 'puppet':
    ensure    => running,
    enable    => true,
    hasstatus => false, # Bypass launchctl status check bug on macOS
    pattern   => 'puppet agent',
  }
}
