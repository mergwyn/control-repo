#
class profile::app::sickbeard_automator {

  $codedir   = '/opt/'
  $target    = "${codedir}/sickbeard_mp4_automator"
  $scriptdir = "${codedir}/scripts"
  $configdir = '/etc/sickbeard_mp4_automator'
  $logdir    = '/var/log/sickbeard_mp4_automator'
  $owner     =  lookup('defaults::media_user')
  $group     =  lookup('defaults::media_group')

  include profile::app::git
  include profile::app::scripts

  #apt::ppa { 'ppa:awyr/ffmpeg-4':
  #  package_manage => true
  #}
  #package { 'ffmpeg':
  #  ensure  => present,
  #  require => Apt::Ppa['ppa:awyr/ffmpeg-4'],
  #}

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
    revision => 'master',
    provider => git,
    require  => [
      Class['profile::app::git'],
  #    Package['ffmpeg'],
    ],
    source   => 'https://github.com/mdhiggins/sickbeard_mp4_automator',
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
    ensure  => file,
    mode    => '0664',
    owner   => $owner,
    group   => $group,
    require => File[$logdir],
  }
}
