#
class profile::app::minio (
  String $version = '2024-03-30T09-41-12Z',  # renovate: datasource=github-releases depName=minio/minio
  String $root_user,
  Sensitive[String] $root_password,
  Stdlib::Absolutepath $data_dir = '/srv/minio',
  Integer $api_port = 9000,
  Integer $console_port = 9001,
  String $listen_address = '0.0.0.0',
) {

  $user = 'minio-user'
  $group = 'minio-user'
  # Create MinIO user
  group { $group:
    ensure => present,
    gid    => 997,
  }

  user { $user:
    ensure     => present,
    uid        => 996,
    gid        => 997,
    home       => '/nonexistent',
    shell      => '/usr/sbin/nologin',
    system     => true,
    managehome => false,
    require    => Group[$group],
  }

  # Ensure data directory exists on ZFS
  file { $data_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
    require => User['minio'],
  }

  # Install MinIO binary using your helper
  profile::app::binary_install { 'minio':
    version     => $version,
    binary      => 'minio',
    url         => "https://dl.min.io/server/minio/release/linux-amd64/minio",
    tarball     => false,
    version_cmd => '/usr/local/bin/minio --version | grep -oP "minio version \K[^ ]+" | cut -d. -f1-4',
    install_dir => '/usr/local/bin',
  }

  # Environment file
  file { '/etc/default/minio':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  shellvar {
    default:
      ensure => present,
      target => '/etc/default/minio',
      notify => Service['minio'],
      ;
    'MINIO_ROOT_USER':         value => $root_user, ;
    'MINIO_ROOT_PASSWORD':     value => $root_password.unwrap, ;
    'MINIO_VOLUMES':           value => $data_dir, ;
    'MINIO_OPTS':              value => "--address ${listen_address}:${api_port} --console-address ${listen_address}:${console_port}", ;
    'MINIO_PROMETHEUS_URL':    value => 'https://prometheus.theclarkhome.com', ;
    'MINIO_PROMETHEUS_JOB_ID': value => 'minio-job', ;
  }

  # Systemd service
  systemd::unit_file { 'minio.service':
    enable  => true,
    active  => true,
    content => @("SERVICE"/L)
      [Unit]
      Description=MinIO
      Documentation=https://min.io/docs/minio/linux/index.html
      Wants=network-online.target
      After=network-online.target
      After=zfs-mount.target
      AssertFileIsExecutable=/usr/local/bin/minio

      [Service]
      User=$user
      Group=$group
      ProtectProc=invisible
      EnvironmentFile=/etc/default/minio
      ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
      ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

      # Let systemd restart this service always
      Restart=always

      # Specifies the maximum file descriptor number that can be opened by this process
      LimitNOFILE=65536

      # Specifies the maximum number of threads this process can create
      TasksMax=infinity

      # Disable timeout logic and wait until process is stopped
      TimeoutStopSec=infinity
      SendSIGKILL=no

      [Install]
      WantedBy=multi-user.target
      | SERVICE,
  }

  # Ensure dependencies are in place before starting the service
  Profile::App::Binary_install['minio'] -> Service['minio']
  File[$data_dir] -> Service['minio']
}
