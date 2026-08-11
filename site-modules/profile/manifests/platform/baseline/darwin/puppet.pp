# @summary Manages the Puppet agent service on Darwin and other platforms.
#
# On Darwin, the Puppet agent is managed through a Puppet-controlled launchd
# plist. The plist is explicitly loaded into launchd before the service resource
# attempts to manage the agent.
#
# On non-Darwin systems, the standard Puppet service resource is used.
#
# @example
#   include profile::platform::baseline::darwin::puppet
#
class profile::platform::baseline::darwin::puppet {
  if $facts['os']['family'] == 'Darwin' {
    file { '/Library/LaunchDaemons/org.voxpupuli.puppet.plist':
      ensure  => file,
      owner   => 'root',
      group   => 'wheel',
      mode    => '0644',
      content => @("PLIST"/L),
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>org.voxpupuli.puppet</string>

          <key>ProgramArguments</key>
          <array>
            <string>/opt/puppetlabs/bin/puppet</string>
            <string>agent</string>
            <string>--verbose</string>
            <string>--no-daemonize</string>
            <string>--logdest</string>
            <string>console</string>
          </array>

          <key>RunAtLoad</key>
          <true/>

          <key>KeepAlive</key>
          <true/>

          <key>StandardOutPath</key>
          <string>/var/log/puppetlabs/puppet/puppet.log</string>

          <key>StandardErrorPath</key>
          <string>/var/log/puppetlabs/puppet/puppet.log</string>

          <key>EnvironmentVariables</key>
          <dict>
            <key>PATH</key>
            <string>/opt/puppetlabs/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
          </dict>
        </dict>
        </plist>
        PLIST
    }

    exec { 'bootstrap puppet launchd':
      command => '/bin/launchctl bootstrap system /Library/LaunchDaemons/org.voxpupuli.puppet.plist',
      unless  => '/bin/launchctl print system/puppet',
      require => File['/Library/LaunchDaemons/org.voxpupuli.puppet.plist'],
    }

    service { 'puppet':
      ensure   => running,
      enable   => true,
      provider => launchd,
      require  => Exec['bootstrap puppet launchd'],
    }
  } else {
    service { 'puppet':
      ensure  => running,
      enable  => true,
      pattern => 'puppet agent',
    }
  }
}
