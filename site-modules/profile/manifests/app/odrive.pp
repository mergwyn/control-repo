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

  $agent_source       = 'https://dl.odrive.com/odriveagent-lnx-64'
  $agent_archive      = basename($agent_source)
  $agent_archive_path = "${facts['puppet_vardir']}/${agent_archive}"
  $creates_agent      = "${install_path}/odriveagent"

  file { $install_path:
    ensure => directory,
  }

  archive { $agent_archive:
    path         => $agent_archive_path,
    source       => $agent_source,
    extract      => true,
    extract_path => $install_path,
    creates      => $creates_agent,
    cleanup      => true,
# TODO notify and require?
  }

  $cli_source       = 'https://dl.odrive.com/odrivecli-lnx-64'
  $cli_archive      = basename($cli_source)
  $cli_archive_path = "${facts['puppet_vardir']}/${cli_archive}"
  $creates_cli      = "${install_path}/odrive"

  archive { $cli_archive:
    path         => $cli_archive_path,
    source       => $cli_source,
    extract      => true,
    extract_path => $install_path,
    creates      => $creates_cli,
    cleanup      => true,
# TODO notify and require?
  }

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
