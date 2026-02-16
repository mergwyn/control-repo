#
#
class profile::app::helmfile (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/helmfile"

  exec { 'install-helmfile':
    creates     => $bin,
    path        => ['/usr/bin', '/bin'],
    subscribe   => Exec['apt_update'],
    refreshonly => false,
    command     => @("EOF"),
      /usr/bin/curl -fsSL https://github.com/helmfile/helmfile/releases/download/v${version}/helmfile_${version}_linux_amd64.tar.gz \
      | /usr/bin/tar -xz -C ${bin_dir} helmfile
      | EOF
  }

  file { $bin:
    mode => '0755',
  }
}
