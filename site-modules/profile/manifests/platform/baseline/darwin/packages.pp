# @summary Packages for Darwin

class profile::platform::baseline::darwin::packages {


  Package {
    provider => brewcask,
    ensure   => latest,
  }

# packages to be removed
  package { 'zoomus':                 ensure => absent }
  package { 'dropbox':                ensure => absent }
  package { 'google-chrome':          ensure => absent }
  package { 'amazon-photos':          ensure => absent }
  package { 'google-backup-and-sync': ensure => absent }
  package { 'onedrive':               ensure => absent }
  package { 'profilecreator':         ensure => absent }
  package { 'plex-media-server':      ensure => absent }

# packages to be installed
  #package { 'amazon-music': }
  package { 'git': provider => 'brew' }
  package { 'unison': provider => 'brew' }

  package { 'firefox': }
  package { 'aerial': }
  package { 'skype': }
  package { 'zoom': }
  package { 'vlc': }
  package { 'keeweb': }
  package { 'puppetlabs/puppet/puppet-agent-6': }
  package { 'homebrew/cask-drivers/sonos':      }
  package { 'plex': }

}
