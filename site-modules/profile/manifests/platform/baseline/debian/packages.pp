# @summary Packages for Debian
#
class profile::platform::baseline::debian::packages {
  Package {
    provider => $facts['os']['family'] ? {
      'Debian' => 'apt',
      'RedHat' => 'yum',
      default  => undef,
    },
  }
  $install_packages = [
    'vim',
    'anacron',
    'gpg',
    'jq',
    'sysstat',
    'btop',
    'inxi',
  ]
  package { $install_packages : ensure => present }

  include profile::app::yq

  $remove_packages = [
    'vim-tiny',
    'mlocate',
  ]
  package { $remove_packages : ensure => absent }
}
