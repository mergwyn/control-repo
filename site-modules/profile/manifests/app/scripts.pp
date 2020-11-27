#

class profile::app::scripts {

  include profile::app::git

  $codedir='/opt/scripts'

  # common scripts
  vcsrepo { $codedir:
      ensure   => latest,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/scripts.git',
      revision => 'master',
  }

  file { "${codedir}/iptv/iptv_urls":
    ensure  => present,
    mode    => '0600',
    content => @("EOT"/$),
               MAGIC_M3U="${lookup('secrets::iptv::m3u::magic')}"
               MAGIC_EPG="${lookup('secrets::iptv::epg::magic')}"
               QUALITY_M3U="${lookup('secrets::iptv::m3u::quality')}"
               QUALITY_EPG="${lookup('secrets::iptv::epg::quality')}"
               OCDTV_M3U="${lookup('secrets::iptv::m3u::ocdtv')}"
               OCDTV_EPG="${lookup('secrets::iptv::epg::ocdtv')}"
               NORD_M3U="${lookup('secrets::iptv::m3u::nord')}"
               NORD_EPG="${lookup('secrets::iptv::epg::nord')}"
               ROUTES=(
               \$NORD_M3U
               )
               | EOT
  }
}
# vim: sw=2:ai:nu expandtab
