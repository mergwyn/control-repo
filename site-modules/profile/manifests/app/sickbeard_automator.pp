# @summary Install and configure sickbeard_mp4_automator
#
#@ param enabletimer
#   Enable the systemctl timer job for process_media_job
class profile::app::sickbeard_automator (
  $enabletimer = true,
  $ffmpegppa   = '',
) {

  $codedir        = '/opt'
  $target         = "${codedir}/sickbeard_mp4_automator"
  $scriptdir      = "${codedir}/scripts"
  $configdir      = '/etc/sickbeard_mp4_automator'
  $sample_ini     = "${target}/setup/autoProcess.ini.sample"
  $target_ini     = "${configdir}/plex.ini"

  $logdir         = '/var/log/sma'
  $logfile        = "${logdir}/sma.log"
  $log_ini        = "${target}/config/logging.ini"
  $venv           = "${target}/venv"
  $requirements   = "${target}/setup/requirements.txt"

  $owner          = lookup('defaults::media_user')
  $group          = lookup('defaults::media_group')
  $adminemail     = lookup('defaults::adminemail')

  #$ffmpegppa      = 'ppa:savoury1/ffmpeg4'

  contain profile::app::git
  contain profile::app::scripts
  contain profile::app::sssd

  if $ffmpegppa =~ String[1] {
    apt::ppa { $ffmpegppa:
      package_manage => true,
      release        => hiera('profile::ubuntu::release'),
    }

    package { 'ffmpeg':
      ensure  => present,
      require => Apt::Ppa[ $ffmpegppa ],
    }
  } else {
    package { 'ffmpeg': ensure  => present, }
  }

# systemd timer to run process_media_job
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
    ExecStart=/bin/bash -c '${scriptdir}/bin/process_media_job 2>&1 | /usr/bin/mailx -E -s "%N output ${owner}@%H" ${adminemail}'

    [Install]
    WantedBy=multi-user.target
    | EOT

  systemd::timer{'process_media.timer':
    timer_content   => $_timer,
    service_content => $_service,
    enable          => $enabletimer,
  }

  # cron job to run scripts
  include cron
  cron::job { 'media': ensure => absent, }

  # Get the lastest version from github
  vcsrepo { $target:
    ensure   => latest,
    #revision => 'e6535dd61d66b0c6de7f2275f58952a1df7f9df8',
    revision => 'master',
    provider => git,
    require  => Service['sssd'],
    source   => 'https://github.com/mdhiggins/sickbeard_mp4_automator',
    notify   => Python::Requirements[$requirements],
    owner    => $owner,
    group    => $group,
  }
  -> python::pyvenv { $venv: # install dependencies
    ensure     => present,
    version    => 'system',
    systempkgs => true,
    owner      => $owner,
    group      => $group,
    require    => [
      Vcsrepo[ $target ],
      Service['sssd'],
    ],
  }
  python::requirements { $requirements :
    virtualenv => $venv,
    owner      => $owner,
    group      => $group,
    require    => [
      Vcsrepo[ $target ],
      Service['sssd'],
    ],
  }

  # Install the configuration file
  file { $configdir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    require => Service['sssd'],
  }

  exec { 'install_sample':
    command => "cp ${sample_ini} ${target_ini}",
    unless  => "test -f ${target_ini} -a ${target_ini} -nt ${sample_ini}",
    creates => $target_ini,
    user    => $owner,
    group   => $group,
    path    => [ '/bin', '/usr/bin' ] ,
    require => [
      Vcsrepo[ $target ],
      File[ $configdir ],
    ],
  }

# add the settings we want to copied autoProcess.ini file from the repo

  $defaults = {
    path    => $target_ini,
    require =>  Vcsrepo[ $target ],
  }
  $settings = {
    'Converter' => {
      ffmpeg           => 'ffmpeg',
      ffprobe          => 'ffprobe',
      delete-original  => 'False',
      output-directory => '/srv/media/.working',
#      output-directory => { ensure => absent },
      output-format    => 'mp4',
      output-extension => 'mp4',
      temp-extension   => 'partial',
      #postopts         => '-ignore_unknown, -max_muxing_queue_size, 1024',
      postopts         => '-ignore_unknown',
      preopts          => '-nostats',
      hwaccels         => 'vaapi',
    },
    'Metadata' => {
      # Check this value
      tag => 'False',
    },
    'Video' => {
      # Check this value
      #max-level => '4.0',
      max-level => '0.0',
      # sample only has h264, x264
      codec     => 'h264vaapi, h264, x264, x265, hevc',
    },
    'Audio' => {
      # Check this value (ac3)
      #codec           => 'aac',
      codec           => 'ac3',
      # Check this value (128)
      #channel-bitrate => '256',
      channel-bitrate => '128',
    },
    #'Universal Audio' => {
      # Check this value (blank)
      #codec => 'aac',
    #},
  }
  inifile::create_ini_settings($settings, $defaults)

# logging settings
  $logdefaults = {
    path    => $log_ini,
    require =>  Vcsrepo[ $target ],
  }
  $logsettings = {
    'handler_fileHandler' => {
      level => 'INFO', # default
      #level => 'DEBUG',
      #args  => "('%(logfilename)s', 'a', 100000, 3)", # default
      args  => "('${logfile}', 'a', 100000, 3)",
    }
  }
  inifile::create_ini_settings($logsettings, $logdefaults)

  #
  # Make sure log file exists and is writable
  file { $logdir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => Service['sssd'],
  }

  file { $logfile:
    ensure  => file,
    mode    => '0664',
    owner   => $owner,
    group   => $group,
    require => [ File[$logdir], Service['sssd'], ],
  }
}
