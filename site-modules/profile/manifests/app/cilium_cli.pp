#
#
class profile::app::cilium_cli (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/cilium"

  exec { 'install-cilium-cli':
    creates     => "${bin_dir}/cilium",
    path        => ['/usr/bin', '/bin'],
    subscribe   => Exec['apt_update'],
    refreshonly => false,
    command     => @("EOF"),
      /usr/bin/curl -L --fail https://github.com/cilium/cilium-cli/releases/download/v${version}/cilium-linux-amd64.tar.gz \
      | /usr/bin/tar -xz -C ${bin_dir} cilium
      | EOF
  }

  file { $bin:
    mode => '0755',
  }
}
