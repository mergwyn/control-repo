#

class profile::media::iptv {
  include cron
  include profile::scripts

  $codedir='/opt/scripts'

  group { 'hts': gid => '900', }
  user { 'hts':
    groups     => 'hts',
    uid        => '900',
    home       => '/var/lib/hts',
    comment    => 'tvheadend,,,',
    managehome => false,
    require    => Group['hts'],
  }

  $packages = [ 'curl', 'socat' ]
  package { $packages: ensure => present }

  class{'::tvheadend':
    release        => 'stable',
    admin_password => 'L1nahswf.ve',
    user           => 'hts',
    group          => 'hts',
    require        => User['hts'],
  } 

  cron::job::multiple { 'xmltv':
    jobs => [
      {
        command     => "test -x ${codedir}/iptv/get-epg && ${codedir}/iptv/get-epg",
        minute      => 30,
        hour        => '2',
      },
      {
        command     => "test -x ${codedir}/iptv/get-channels && ${codedir}/iptv/get-channels",
        minute      => 20,
        hour        => '4,12,16',
      },
    ],
    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
  }

  #TODO tvhproxy
  #TODO telly
}

# vim: sw=2:ai:nu expandtab
