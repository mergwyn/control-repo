# @summary Manages MinIO object storage server
#
# Installs and configures MinIO, including TLS via acme.sh wildcard cert.
#
# @param version
#   MinIO release version string.
#   renovate: datasource=github-releases depName=minio/minio extractVersion=^RELEASE\.(?<version>.+)$
# @param root_user
#   MinIO root username, sourced from Hiera secrets.
# @param root_password
#   MinIO root password, sourced from Hiera secrets.
# @param data_dir
#   Absolute path to the MinIO data directory (expects ZFS mount).
# @param api_port
#   Port for the MinIO S3 API.
# @param console_port
#   Port for the MinIO web console.
# @param listen_address
#   Address MinIO binds to.
# @param certs_dir
#   Directory MinIO reads TLS certs from. Expects public.crt and private.key.
# @param cert_source
#   Absolute path to the acme.sh-managed certificate file.
# @param key_source
#   Absolute path to the acme.sh-managed private key file.
class profile::app::minio (
  String                $version         = '2025-09-07T16-13-09Z', #renovate: datasource=github-releases depName=minio/minio extractVersion=^RELEASE\.(?<version>.+)$
  String                $root_user       = lookup('secrets::minio_root'),
  String                $root_password   = lookup('secrets::minio_root_password'),
  Stdlib::Absolutepath  $data_dir        = '/srv/minio',
  Integer               $api_port        = 9000,
  Integer               $console_port    = 9001,
  String                $listen_address  = '0.0.0.0',
  Stdlib::Absolutepath  $certs_dir       = '/etc/minio/certs',
  Stdlib::Absolutepath  $cert_source     = "/etc/acme/wildcard.${trusted['domain']}/fullchain.pem",
  Stdlib::Absolutepath  $key_source      = "/etc/acme/wildcard.${trusted['domain']}/private.key",
) {
  $user  = 'minio-user'
  $group = 'minio-user'
  $uid   = 2001
  $gid   = 2001

  # User and group
  group { $group:
    ensure => present,
    gid    => $gid,
  }

  user { $user:
    ensure     => present,
    uid        => $uid,
    gid        => $gid,
    home       => '/nonexistent',
    shell      => '/usr/sbin/nologin',
    system     => true,
    managehome => false,
    require    => Group[$group],
  }

  # Data directory (ZFS)
  file { $data_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0750',
    require => User[$user],
  }

  include profile::app::acme

  # Certs directory
  # Break the path down into an array of parent paths
  $dir_tree = prefix(split(regsubst($certs_dir, '^/', ''), '/'), '/')
  # Filter out system directories you don't want Puppet managing (like /etc itself)
  $target_dirs = $dir_tree.filter |$dir| { $dir != '/' and $dir != '/etc' }

  # Loop through and create them in order
  $target_dirs.each |$dir| {
    ensure_resource('file', $dir, {
      'ensure'  => directory,
      'owner'   => $user,
      'group'   => $group,
      'mode'    => '0750',
      'require' => User[$user],
    })
  }

  # Certificate files — copied from acme.sh output
  file { "${certs_dir}/public.crt":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    source  => $cert_source,
    require => File[$certs_dir],
    notify  => Service['minio.service'],
  }

  file { "${certs_dir}/private.key":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    source  => $key_source,
    require => File[$certs_dir],
    notify  => Service['minio.service'],
  }

  # Binary
  profile::app::binary_install { 'minio':
    version     => $version,
    binary      => 'minio',
    url         => "https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.${version}",
    tarball     => false,
    version_cmd => '/usr/local/bin/minio --version | grep -oP "minio version RELEASE.\K[^ ]+" | cut -d. -f1-4',
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
      notify => Service['minio.service'],
      ;
    'MINIO_ROOT_USER':            value => $root_user, ;
    'MINIO_ROOT_PASSWORD':        value => $root_password, ;
    'MINIO_VOLUMES':              value => $data_dir, ;
    'MINIO_OPTS':                 value => "--address ${listen_address}:${api_port} --console-address ${listen_address}:${console_port} --certs-dir ${certs_dir}", ;
    'MINIO_BROWSER_REDIRECT_URL': value => "https://${trusted['hostname']}.${trusted['domain']}:${api_port}", ;
    'MINIO_PROMETHEUS_URL':       value => "https://prometheus.${trusted['domain']}", ;
    'MINIO_PROMETHEUS_JOB_ID':    value => 'minio-job', ;
  }

  # Systemd service
  systemd::unit_file { 'minio.service':
    enable  => true,
    active  => true,
    content => @("SERVICE"/L$),
      [Unit]
      Description=MinIO
      Documentation=https://min.io/docs/minio/linux/index.html
      Wants=network-online.target
      After=network-online.target
      After=zfs-mount.target
      AssertFileIsExecutable=/usr/local/bin/minio

      [Service]
      User=${user}
      Group=${group}
      ProtectProc=invisible
      EnvironmentFile=/etc/default/minio
      ExecStartPre=/bin/bash -c "if [ -z \"\${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
      ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES
      Restart=always
      LimitNOFILE=65536
      TasksMax=infinity
      TimeoutStopSec=infinity
      SendSIGKILL=no

      [Install]
      WantedBy=multi-user.target
      | SERVICE
  }

  Profile::App::Binary_install['minio'] ~> Service['minio.service']
  File[$data_dir]               -> Service['minio.service']
  File["${certs_dir}/public.crt"]  -> Service['minio.service']
  File["${certs_dir}/private.key"] -> Service['minio.service']
}
