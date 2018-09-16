#

class profile::transcoder {
  include profile::git

  $codedir='/opt/code/scripts'

  # lxd snap related commands
  vcsrepo { $codedir:
      ensure   => present,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/scripts.git',
      revision => 'master',
  }

  include cron
  cron::job { 'media':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => "test -x ${codedir}/bin/process_media_job && ${codedir}/bin/process_media_job",
    user        => 'media',
    minute      => 5,
    hour        => '0-18',
  }


  #setup systemd entry
  systemd::unit_file { 'humaxscan.service':
    enable  => true,
    active  => true,
    content => "[Unit]
Description=Scan for presence of Humax PVR and notify plex
After=multi-user.target

[Service]
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=${codedir}/bin/humaxscan
TimeoutStopSec=20
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
"
    }
}
# vim: sw=2:ai:nu expandtab
