#
#
class profile::platform::baseline::debian::virtual::docker {

# TODO woraround for https://github.com/puppetlabs/puppetlabs-docker/issues/870
  if $facts['virtual'] == 'lxc' {
    package  { [ 'fuse-overlayfs' ]: }
  }

  $docker_users = [ 'gary' ]
  $additional_packages = [ 'containerd.io', 'docker-compose-plugin' ]

  $ensure = absent

  class { 'docker':
    ensure       => $ensure,
    docker_users => $docker_users,
  }
  -> package { $additional_packages: ensure => $ensure }

}
