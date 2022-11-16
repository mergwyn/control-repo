#
#
class profile::platform::baseline::debian::virtual::docker {

# TODO woraround for https://github.com/puppetlabs/puppetlabs-docker/issues/870
  if $facts['virtual'] == 'lxc' {
#    package  { [ 'fuse-overlayfs' ]: }
    $storage_driver = 'fuse-overlayfs'
#    $storage_driver = 'vfs'
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
