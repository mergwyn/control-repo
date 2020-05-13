#

class profile::web::nginx {

  include nginx
  # define nginx config
  #class { 'nginx':
  #  nginx_cfg_prepend => {
  #    include => [ '/etc/nginx/modules-enabled/*.conf' ],
  #  }
  #}
  package { [ 'fcgiwrap' ]: }
}

