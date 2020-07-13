# @summary Packages for Debian

class profile::platform::baseline::debian::packages {


# packages to be installed
  Package {
    ensure   => present,
  }

  package { 'vim': }
  package { 'anacron': }
  package { 'gpg': }

  package { 'vim-tiny': ensure => absent }
  package { 'mlocate':  ensure => absent }

}
