#
class profile::media::sickbeard_automator {

  $codedir   = '/opt/'
  $target    = "${codedir}/sickbeard_mp4_automator"
  $scriptdir = "${codedir}/scripts"
  $configdir = '/etc/sickbeard_mp4_automator'
  $logdir    = '/var/log/sickbeard_mp4_automator'
  $owner     =  hiera('defaults::media_user')
  $group     =  hiera('defaults::media_group')

  include profile::git
  include profile::scripts

  apt::ppa { 'ppa:jonathonf/ffmpeg-4':
    package_manage => true
  }
  package { 'ffmpeg':
    ensure  => present,
    require => Apt::Ppa['ppa:jonathonf/ffmpeg-4'],
  }

  # cron job to run scripts
  include cron
  cron::job { 'media':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => "test -x ${scriptdir}/bin/process_media_job && ${scriptdir}/bin/process_media_job",
    user        => $owner,
    minute      => 5,
    hour        => '0-18',
  }

  # Get the lastest version from github
  vcsrepo { $target:
    ensure   => latest,
    provider => git,
    require  => [
      Class['profile::git'],
      Package['ffmpeg'],
    ],
    source   => 'https://github.com/mdhiggins/sickbeard_mp4_automator',
    revision => 'master',
    owner    => $owner,
    group    => $group,
  }
  #TODO install dependencies
  # Install the configuration file
  file { $configdir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }
  file { "${configdir}/plex.ini":
    ensure  => file,
    source  => 'puppet:///modules/profile/plex.ini',
    owner   => $owner,
    group   => $group,
    require => File[$configdir],
  }
  #
  #TODO change logging parameters?
  # Make sure log file exists and is writable
  file { $logdir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '0777',
  }
  file { "${logdir}/index.log":
    ensure => file,
    mode   => '0664',
    owner  => $owner,
    group  => $group,
    require => File[$logdir],
  }
}

# vim: sw=2:ai:nu expandtab
