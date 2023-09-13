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
    'puppetlabs/puppet/puppet-agent-7',
    'sonos',
    'plex',
  ]

  package { $casks: }
}
