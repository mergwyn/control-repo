# @summary Packages for Darwin
#
class profile::platform::baseline::darwin::packages {

  Package {
    provider => brewcask,
    ensure   => latest,
  }

# packages to be installed
  #package { 'amazon-music': }
  $taps = [
    'git',
    'unison',
    'python',
    'python-tk',
  ]
  package { $taps: provider => 'brew' }

  $casks = [
    'firefox',
    'aerial',
    'skype',
    'zoom',
    'vlc',
    'keeweb',
    'puppetlabs/puppet/puppet-agent-6',
    'homebrew/cask-drivers/sonos',
    'plex',
  ]

  package { $casks: }
}
