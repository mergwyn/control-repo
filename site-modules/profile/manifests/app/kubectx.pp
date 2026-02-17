#
#
class profile::app::kubectx (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/kubectx"

  exec { 'install-kubectx':
    command => @(END),
      curl -fsSL https://github.com/ahmetb/kubectx/releases/download/v${version}/kubectx_v${version}_linux_x86_64.tar.gz \
        | tar -xz -C ${bin_dir}
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
