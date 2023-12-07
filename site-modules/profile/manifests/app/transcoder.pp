#
#
class profile::app::transcoder {

  $codedir = '/opt'
  $scriptdir = "${codedir}/scripts"

  include profile::app::git
  include profile::app::scripts
  include profile::app::sickbeard_automator

  stdlib::ensure_packages ( [ 'nfs-common' ], { ensure => present } )



  #setup systemd entry
  systemd::unit_file { 'humaxscan.service':
    enable  => true,
    active  => true,
    content => @("EOT"),
                [Unit]
                Description=Scan for presence of Humax PVR and notify plex
                After=multi-user.target

                [Service]
                Restart=on-failure
                RestartSec=5
                Type=simple
                ExecStart=${scriptdir}/bin/humaxscan
                TimeoutStopSec=20
                StartLimitInterval=60s
                StartLimitBurst=3

                [Install]
                WantedBy=multi-user.target
                | EOT
    }
}
# vim: sw=2:ai:nu expandtab
