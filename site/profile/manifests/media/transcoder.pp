#

class profile::media::transcoder {

  include profile::git
  include profile::scripts

  $packages = [ 'nfs-common' ]
  package { $packages: ensure => present }

  $codedir='/opt/scripts'

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
