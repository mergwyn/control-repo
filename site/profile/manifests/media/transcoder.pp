#

class profile::media::transcoder {

  include profile::git
  include profile::scripts
  include profile::media::sickbeard_automator

  $packages = [ 'nfs-common' ]
  package { $packages: ensure => present }


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
