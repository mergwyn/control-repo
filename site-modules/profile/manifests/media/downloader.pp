#

class profile::media::downloader () {

  #TODO insert dependency on mono into module
  include profile::media::mono
  include ::jackett
  include profile::media::sonarr
  include profile::app::couchpotato
  include profile::app::sabnzbdplus
  include profile::app::sonarr
  include profile::app::transmission
  include profile::app::radarr
}
# vim: sw=2:ai:nu expandtab
