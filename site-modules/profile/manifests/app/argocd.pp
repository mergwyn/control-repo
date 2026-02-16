#
#
class profile::app::argocd (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/argocd"

  exec { 'install-argocd':
    command => @(END),
      curl -fsSL https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-amd64 -o ${bin}
      chmod +x ${bin}
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
