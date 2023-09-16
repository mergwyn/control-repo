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

  $puppetver = $facts['os']['macosx']['version']['major'] ? {
    /10.13/ => '6',
    default => '7',
  }

  $casks = [
    'firefox',
    'aerial',
    'skype',
    'zoom',
    'vlc',
    'sonos',
    'plex',
    "puppetlabs/puppet/puppet-agent-${puppetver}",
  ]

  package { $casks: }
}
