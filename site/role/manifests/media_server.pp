# vim: sw=2:ai:nu expandtab

class role::media_server {
  include profile::base  # All roles should have the base profile
  include profile::domain::member
  include profile::domain::sso
  include profile::sabnzbdplus
  include profile::transmission
  include profile::couchpotato
  include profile::sonarr
  include profile::media::download_server
  include profile::tvheadend
  include profile::transcoder
}
