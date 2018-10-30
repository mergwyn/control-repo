#
class profile::media::sickbeard_automator {

  $codedir='/opt/'
  $target="${codedir}/sickbeard_mp4_automator"
  $scriptdir = ${codedir}/scripts"
  $packages = [ 'nfs-common' ]

  include profile::git
  include profile::scripts

  package { $packages: ensure => present }

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
    user        => 'media',
    minute      => 5,
    hour        => '0-18',
  }

  # remainder of module relates to  sickbeard_mp4_automator
  vcsrepo { $target:
    ensure   => latest,
    provider => git,
    require  => [
      Class['profile::git'],
      Package['ffmpeg'],
    ],
    source   => 'https://github.com/mdhiggins/sickbeard_mp4_automator',
    revision => 'master',
  }
  #TODO install dependencies
  $configdir = '/etc/sickbeard_mp4_automator'
  file { $configdir:
    ensure => directory,
  }
  file { "${configdir}/plex.ini":
    ensure => file,
    source => 'puppet:///modules/profile/plex.ini',
  }
  #
  #TODO change logging parameters?
  $logpath = '/var/log/sickbeard_mp4_automator'
  file { $logpath:
    ensure => directory,
    mode   => '0777',
  }
  file { "${logpath}/index.log":
    ensure => file,
    mode   => '0666',
    require => File[$logpath],
  }
}

# vim: sw=2:ai:nu expandtab
