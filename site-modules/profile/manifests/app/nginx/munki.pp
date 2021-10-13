#
#
class profile::app::nginx::munki {
  include profile::app::nginx

  nginx::resource::server { 'munki_repo':,
    ensure => absent,
  }
}
