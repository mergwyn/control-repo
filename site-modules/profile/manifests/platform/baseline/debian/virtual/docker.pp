#
#
class profile::platform::baseline::debian::virtual::docker {

  $docker_users = [ 'gary' ]

  clase { 'docker':
    ensure       => present,
    docker_users => $docker_users,
  }

}
