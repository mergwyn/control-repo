#
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

  file { '/etc/profile.d/scripts.sh':
    ensure  => file,
    content => @("EOT"/),
               # Expand the PATH to include my scripts
               if [ -z "\${PATH-}" ] ; then
                 export PATH=${codedir}/bin
               elif ! echo "\${PATH}" | grep -q ${codedir}/bin ; then
                 export PATH="\${PATH}:${codedir}/bin"
               fi
               PATH=\$PATH:${codedir}/bin
               | EOT
  }

  # TODO: remove
  file { "${codedir}/iptv/iptv_urls":
    ensure  => file,
    mode    => '0600',
    content => @("EOT"/$),
               PLEX_TOKEN="${lookup('secrets::iptv::plex::token')}"
               ICE_M3U="${lookup('secrets::iptv::m3u::iceflashott')}"
               ICE_EPG="${lookup('secrets::iptv::epg::iceflashott')}"
               ROUTES=(
               \$ICE_M3U
               )
               | EOT
  }
}
