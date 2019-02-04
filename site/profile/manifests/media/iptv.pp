#

class profile::media::iptv {
  include cron
  include profile::scripts

  $codedir='/opt/scripts'

  $packages = [ 'curl', 'socat' ]
  package { $packages: ensure => present }

  class{'::tvheadend':
    release        => 'stable',
    admin_password => 'L1nahswf.ve',
  }

  $content = @("EOT")
     MAGIC_M3U='http://watchthis.uk:80/get.php?${lookup('secrets::magic')}&output=ts&type=m3u_plus'
     MAGIC_EPG='http://watchthis.uk/xmltv.php?${lookup('secrets::magic')}'
     | EOT
  file { "${codedir}/iptv/iptv_urls":
    ensure  => present,
    owner   => 'media',
    group   => '513',
    mode    => '0600',
    content => $content,
  }

  cron::job::multiple { 'xmltv':
    jobs        => [
      {
        command => "test -x ${codedir}/iptv/get-epg && ${codedir}/iptv/get-epg",
        minute  => 30,
        hour    => '*',
      },
      {
        command => "test -x ${codedir}/iptv/get-channels && ${codedir}/iptv/get-channels",
        minute  => 20,
        hour    => '4,12,16',
      },
    ],
    environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
  }

  #TODO tvhproxy
  #TODO telly
  include profile::web::xmltv
}

# vim: sw=2:ai:nu expandtab
