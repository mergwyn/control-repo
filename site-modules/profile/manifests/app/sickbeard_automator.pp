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

  #$ffmpegppa='ppa:awyr/ffmpeg-4'
  #$ffmpegppa='ppa:savoury1/ffmpeg4
  #apt::ppa { ${ffmpegppa}:
  #  package_manage => true
  #}
  #package { 'ffmpeg':
  #  ensure  => present,
  #  require => Apt::Ppa[ ${ffmpegppa} ],
  #}

# systemd timer to run process_media_job
  $adminemail = lookup('defaults::adminemail')
  $_timer = @(EOT)
    [Unit]
    Description=Run process_media on boot and hourly

    [Timer]
    OnBootSec=10min
    OnUnitActiveSec=1h

    [Install]
    WantedBy=timers.target
    | EOT

  $_service = @("EOT")
    [Unit]
    Description=runs process_media
    Wants=process_media.timer

    [Service]
    Type=simple
    User=${owner}
    ExecStart=/bin/bash -c '${scriptdir}/bin/process_media_job 2> >(/usr/bin/mailx -v -E -s "%N output %u@%H" ${adminemail})'

    [Install]
    WantedBy=multi-user.target
    | EOT

  systemd::timer{'process_media.timer':
    timer_content   => $_timer,
    service_content => $_service,
    enable          => true,
    active          => true,
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
# TODO add just the settings we want to the repository autoProcess.ini file
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
