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
    ExecStart=/bin/bash -c '${scriptdir}/bin/process_media_job | /usr/bin/mailx -v -E -s "%N output %u@%H"" ${adminemail}'

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
