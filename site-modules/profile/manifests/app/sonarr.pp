# @summary Install sonarr
#
class profile::app::sonarr (
  $user  = 'media',
  $group = '513',
  ) {
  # repo
  apt::source { 'sonarr':
    location => 'https://apt.sonarr.tv/ubuntu',
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    key      => {
      #'id'     => 'FDA5DFFC',
      'id'     => 'A236C58F409091A18ACA53CBEBFF6B99D9B78493',
      'server' => 'keyserver.ubuntu.com',
    },
    include  => {
      'deb' => true,
    },
  }

# setup preseed to supply user and group
  $preseed = '/var/cache/debconf/sonarr.preseed'
  file { $preseed:
    ensure  => present,
    content => @("EOT"/),
               sonarr	sonarr/owning_user	string	${user}
               sonarr	sonarr/owning_group	string	${group}
               | EOT
  }

# install and make sure service is running
  package { 'sonarr':
    ensure       => latest,
    responsefile => $preseed,
    require      => File[$preseed],
  }
  service { 'sonarr':
    ensure  => 'running',
    enable  => true,
    require => Package['sonarr'],
  }
}
