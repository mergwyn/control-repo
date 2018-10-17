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
  file { '/etc/systemd/system/sonarr.service':
    ensure  => present,
    notify  => [
      Exec['systemctl-daemon-reload'],
      Service['sonarr'],
    ],
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
ExecStop=-/usr/bin/mono /tmp/nzbdrone_update/NzbDrone.Update.exe \\`ps aux | grep NzbDrone | grep -v grep | awk '{ print $2 }'\\` /tmp/nzbdrone_update /opt/NzbDrone/NzbDrone.exe
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
