#
#
class profile::app::kustomize (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/kustomize"

  exec { 'install-kustomize':
    command => @(END),
      curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${version}/kustomize_v${version}_linux_amd64.tar.gz \
        | tar -xz -C ${bin_dir} kustomize
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
