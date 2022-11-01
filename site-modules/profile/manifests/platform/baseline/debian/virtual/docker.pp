#
#
class profile::platform::baseline::debian::virtual::docker {

  $docker_users = [ 'gary' ]
  $additional_packages = [ 'docker-compose-plugin' ]

  class { 'docker':
    ensure       => present,
    docker_users => $docker_users,
  }
  -> package { $additional_packages: }


}
