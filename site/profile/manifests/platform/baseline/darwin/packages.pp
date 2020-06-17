# @summary Packages for Darwin

class profile::platform::baseline::darwin::packages {


# packages to be installed
  Package {
    provider => homebrew,
    ensure   => latest,
  }

  package { 'amazon-music': }
  package { 'firefox': }
  package { 'aerial': }
  package { 'skype': }
  package { 'zoomus': }
  package { 'vlc': }
  package { 'keeweb': }
  package { 'mergwyn/homebrew-cask/unison248':  provder => tap }
  package { 'puppetlabs/puppet/puppet-agent-6': provder => tap }
  package { 'homebrew/cask-drivers/sonos':      provder => tap }

  package { 'dropbox':                ensure => absent }
  package { 'google-chrome':          ensure => absent }
  package { 'amazon-photos':          ensure => absent }
  package { 'google-backup-and-sync': ensure => absent }
  package { 'onedrive':               ensure => absent }
  package { 'profilecreator':         ensure => absent }

}
