#
#
class profile::platform::baseline::debian::virtual::docker {

  if $facts['virtual'] == 'lxc' {
    package  { [ 'fuse-overlayfs' ]: }
    $storage_driver = 'fuse-overlayfs'
  } else {
    $storage_driver = 'zfs'
  }

  $docker_users = [ 'gary' ]
  $additional_packages = [ 'docker-compose-plugin' ]

  class { 'docker':
    ensure         => present,
    docker_users   => $docker_users,
    storage_driver => $storage_driver,
  }
  -> package { $additional_packages: }


}
