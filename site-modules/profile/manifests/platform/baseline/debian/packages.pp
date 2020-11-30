# @summary Packages for Debian

class profile::platform::baseline::debian::packages {

  $install_packages = [
    'vim',
    'anacron',
    'gpg',
    'jq',
  ]
  package { $installpackages: ensure => present }

  $remove_packages = [
    'vim-tiny',
    'mlocate',
  ]
  package { $remove_packages: ensure => absent }

}
