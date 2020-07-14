#

class profile::web::munki {
  include profile::web::nginx

  nginx::resource::server { 'munki_repo':,
    ensure => absent,
  }
}

#
# vim:  sw=2:ai:nu expandtab
