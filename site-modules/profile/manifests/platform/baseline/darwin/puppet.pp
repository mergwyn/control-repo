class profile::platform::baseline::darwin::puppet {
  if $facts['os']['family'] == 'Darwin' {
    # Only load/kickstart the daemon if the agent process isn't running at all
    exec { 'ensure_puppet_daemon_running':
      command => '/bin/launchctl bootstrap system /Library/LaunchDaemons/org.voxpupuli.puppet.plist',
      unless  => '/bin/pgrep -f "puppet agent"',
    }
  } else {
    service { 'puppet':
      ensure => running,
      enable => true,
    }
  }
}

