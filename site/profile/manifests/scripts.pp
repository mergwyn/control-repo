#

class profile::scripts {

  include profile::git

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
    content => @("EOT"),
               MAGIC_M3U="${lookup('secrets::iptv::m3u::magic')}"
               MAGIC_EPG="${lookup('secrets::iptv::epg::magic')}"
               | EOT
  }
}
# vim: sw=2:ai:nu expandtab
