#

class profile::media::downloader () {

  #TODO insert dependency on mono into module
  include profile::media::mono
  include ::jackett
  include ::radarr
  include profile::media::sonarr
  include profile::media::couchpotato
  include profile::app::sabnzbdplus
  include profile::media::sonarr
  include profile::app::transmission
}
# vim: sw=2:ai:nu expandtab
