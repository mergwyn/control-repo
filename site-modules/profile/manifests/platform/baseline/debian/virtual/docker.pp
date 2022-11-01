#
#
class profile::platform::baseline::debian::virtual::docker {

  $docker_users = [ 'gary' ]

  class { 'docker':
    ensure       => present,
    docker_users => $docker_users,
  }

}
