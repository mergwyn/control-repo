#

class profile::media::iptv {
  $packages = [ 'curl', 'socat' ]
  package { $packages: ensure => present }

  #class{'::tvheadend':
    #release        => 'stable-4.2',
    #admin_password => 'L1nahswf.ve',
    #user           => 'media',
    #group          => '513',
  #} 
  #TODO cron
  #TODO tvhproxy
}

# vim: sw=2:ai:nu expandtab
