#

class profile::media::downloader () {

  #TODO insert dependency on mono into module
  include profile::media::mono
  include ::jackett
  include ::radarr
}
# vim: sw=2:ai:nu expandtab
