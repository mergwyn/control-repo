# @summary installanf configure odrive
#

class profile::app::odrive (
  $users  = ['gary'],
) {
  $codedir='/opt/odrive'

  # automatically start daemon
  systemd::unit_file { 'odrive-agent@.service':
    enable  => true,
    active  => false,
    content => @("EOT"),
               [Unit]
               Description=odrive Sync Agent daemon for %I
               After=network.target
 
               [Service]
               User=%I
               ExecStart=${codedir}/bin/odriveagent
               ExecStop=${codedir}/bin/odrive shutdown
               ExecStartPost=/bin/sleep 60
               StartLimitBurst=5
               RestartSec=5
 
               [Install]
               WantedBy=default.target
               | EOT
  }

  systemd::unit_file { 'odrive-monitor@.service':
    enable  => true,
    active  => false,
    content => @("EOT"),
               [Unit]
               Description=odrive monitoring daemon for %i
               After=network.target odrive-agent@%i.service
               Wants=odrive-agent@%i.service
               PartOf=odrive-agent@%i.service
 
               [Service]
               User=%i
               # Alllow time for the agent to initialise
               ExecStart=${codedir}/odrivemonitor
               StartLimitBurst=5
               Restart=on-failure
               RestartSec=10
 
               [Install]
               WantedBy=default.target
               | EOT
  }

#TODO Install package and utilities
  include profile::app::git

  package{'inotify-tools': ensure => present }

  # common scripts
  vcsrepo { $codedir:
      ensure   => latest,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/odrive.git',
      revision => 'main',
  }

  $install_path = "${codedir}/bin"

  profile::app::odrive::install { 'odriveagent': install_path => $install_path }
  profile::app::odrive::install { 'odrivecli':   install_path => $install_path }

  $users.each |String $user| {
    service { "odrive-agent@${user}":
      ensure  => 'running',
      enable  => true,
      require => Vcsrepo[$codedir],
# TODO notify and require?
    }
    service { "odrive-monitor@${user}":
      ensure  => 'running',
      enable  => true,
      require => Vcsrepo[$codedir],
# TODO notify and require?
    }
  }
}
