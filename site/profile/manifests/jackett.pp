#
# TODO: 

class profile::jackett () {

  $install_path   = '/opt'
  $package_name   = 'Jackett.Binaries.Mono'
  $package_ensure = $::jacket_ver
  $repository_url = 'https://github.com/Jackett/Jackett/releases/download/'
  $package_source = "${repository_url}/${package_ensure}/${package_name}.tar.gz"
  $archive_name   = "${package_name}-${package_ensure}.tgz"

  archive { 'app_package_zip':
    path         => "/opt/${package_name}_${package_ensure}.tar.gz",
    source       => $package_source,
    user         => 'media',
    group        => 'domain\x20users',
    extract      => true,
    extract_path => $install_path,
    creates      => $package_source
    cleanup      => false,
  }

  #setup systemd entry
  systemd::unit_file { 'jackett.service':
    enable  => true,
    active  => true,
    content => '[Unit]
Description=Jackett Daemon
After=network.target

[Service]
User=media
Restart=always
RestartSec=5
Type=simple
ExecStart=/usr/bin/mono --debug /opt/Jackett/JackettConsole.exe --NoRestart
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
'
    }
}
# vim: sw=2:ai:nu expandtab
