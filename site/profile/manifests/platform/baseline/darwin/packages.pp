# @summary Packages for Darwin

class profile::platform::baseline::darwin::packages {


# packages to be installed
  Package {
    provider => homebrew,
    ensure   => latest,
  }

  package { 'mergwyn/homebrew-cask/unison248': }
  package { 'puppetlabs/puppet/puppet-agent-6': }
  package { 'keeweb': }
  package { 'amazon-music': }
  package { 'firefox': }
  package { 'homebrew/cask-drivers/sonos': }
  package { 'profilecreator': }
  package { 'aerial': }
  package { 'skype': }
  package { 'zoomus': }
  package { 'vlc': }

  package { 'dropbox':                ensure => absent }
  package { 'google-chrome':          ensure => absent }
  package { 'amazon-photos':          ensure => absent }
  package { 'google-backup-and-sync': ensure => absent }
  package { 'onedrive':               ensure => absent }

}
