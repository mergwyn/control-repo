#

class profile::web::nginx {

  # TODO: move to hiera
  include nginx
  package { [ 'fcgiwrap' ]: }
}

