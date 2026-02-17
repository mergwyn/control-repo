#
#
class profile::app::helm (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/helm"

  # --- download and extract helm ---
  exec { 'install-helm':
    command => @(END),
      curl -fsSL https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz \
        | tar -xz --strip-components=1 -C ${bin_dir} linux-amd64/helm
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
