#
#
class profile::app::downloader () {

  #TODO insert dependency on mono into module
  include profile::app::mono
  include ::jackett
  include profile::app::sonarr
  include profile::app::couchpotato
  include profile::app::sabnzbdplus
  include profile::app::sonarr
  include profile::app::transmission
  include profile::app::radarr
}
