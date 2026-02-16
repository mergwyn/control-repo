#
#
class profile::app::sops (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/sops"

  exec { 'install-sops':
    command => @(END),
      curl -fsSL https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.linux.amd64 -o ${bin}
      chmod +x ${bin}
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
