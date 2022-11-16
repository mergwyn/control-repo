#
#
class profile::platform::baseline::debian::virtual::docker {

  if $facts['virtual'] == 'lxc' {
    $required_packages = [ 'fuse-overlayfs' ]
    $storage_driver = 'fuse-overlayfs'
  }

  $docker_users = [ 'gary' ]
  $additional_packages = [ 'docker-compose-plugin' ]

  package { $required_packages: }
  -> class { 'docker':
    ensure       => present,
    docker_users => $docker_users,
  }
  -> package { $additional_packages: }


}
