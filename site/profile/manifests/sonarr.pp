#

# TODO settings, systemd unit file

class profile::sonarr (
  $user  = 'media',
  $group = '513',
  ) {
  # repo
  apt::source { 'sonarr':
    location => 'http://apt.sonarr.tv/',
    release  => 'master',
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
  # automatically start daemon
  systemd::unit_file { 'sonarr.service':
    enable  => true,
    active  => true,
    content => "
[Unit]
Description=Sonarr Daemon
RequiresMountsFor=/srv/media /home/media

[Service]
User=$user
Group=$group
Restart=always
RestartSec=5
Type=simple
ExecStart=/usr/bin/mono /opt/NzbDrone/NzbDrone.exe -nobrowser
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
",
  }

  # finally install package and start service
  package { 'nzbdrone': }
  service { 'sonarr':
    ensure  => 'running',
    enable  => true,
    require => Package['nzbdrone'],
  }
}
# vim: sw=2:ai:nu expandtab
