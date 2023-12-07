#
#
class profile::platform::baseline::debian::virtual::docker {

# TODO woraround for https://github.com/puppetlabs/puppetlabs-docker/issues/870
  if $facts['virtual'] == 'lxc' {
    package  { [ 'fuse-overlayfs' ]: }
  }
#
#  $docker_users = [ 'gary' ]
#  $additional_packages = [ 'docker-compose-plugin' ]
#
#  class { 'docker':
#    ensure       => present,
#    docker_users => $docker_users,
#  }
#  -> package { $additional_packages: }

}
