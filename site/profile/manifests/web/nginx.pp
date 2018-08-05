#

class profile::web::nginx {

  # define nginx config
  class { 'nginx':
    nginx_cfg_prepend => {
      include => [ '/etc/nginx/modules-enabled/*.conf' ],
    }
  }
  package { [ 'fcgiwrap' ]: }
}

#
# vim:  sw=2:ai:nu expandtab
