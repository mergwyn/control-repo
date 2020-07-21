# vim: sw=2:ai:nu expandtab
# TODO settings, systemd service file (external or ERB?)

class profile::media::couchpotato (
  $user = media,
  $group = '513',
  $data  = '/var/cache/couchpotato',
  $run   = '/var/run/couchpotato/',
  ) {
  include profile::git
  $topdir='/opt'
  $targetdir="${topdir}/CouchPotatoServer"

  exec{ 'cloneCouchpotato':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "test -d '${targetdir}'",
    command => "git -C ${topdir} clone https://github.com/CouchPotato/CouchPotatoServer.git",
    require => Class[ 'profile::git' ],
  }
  # TODO settings

  # automatically start daemon
  systemd::unit_file { 'couchpotato.service':
    enable  => false,
    active  => false,
    # lint:ignore:140chars
    content => @("EOT"),
      # Systemd service file
      [Unit]
      Description=couchpotato daemon
      RequiresMountsFor=/srv/media /home/media
      After=nss-user-lookup.target

      [Service]
      User=${user}
      Group=${group}
      UMask=002
      Type=simple
      WorkingDirectory=${topdir}/CouchPotatoServer/
      ExecStart=${topdir}/CouchPotatoServer/CouchPotato.py --pid_file ${run}/couchpotato.pid --config_file /home/media/.config/couchpotato/settings.conf --data_dir ${data}

      [Install]
      WantedBy=multi-user.target
      | EOT
    # lint:endignore
  }

  file { $data:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  # finally install package and start service
  #service { 'couchpotato':
  #  ensure  => 'stopped',
  #  enable  => true,
  #}
#service { 'couchpotato':
  #  ensure  => 'running',
  #  enable  => true,
  #  require => Package['couchpotato'],
  #}
}
