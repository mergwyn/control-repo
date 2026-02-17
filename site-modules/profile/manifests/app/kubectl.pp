#
#
class profile::app::kubectl (
  String  $version,
) {
  $bin_dir = '/usr/local/bin'
  $kubectl = "${bin_dir}/kubectl"
  $k3s     = "${bin_dir}/k3s"

  # --- k3s case: kubectl is a symlink ---
  exec { 'kubectl-symlink-to-k3s':
    command => "/bin/ln -sf ${k3s} ${kubectl}",
    creates => $kubectl,
    onlyif  => "/usr/bin/test -x ${k3s}",
    path    => ['/bin', '/usr/bin'],
  }

  # --- non-k3s case: install kubectl binary ---
  exec { 'install-kubectl':
    command => @(END),
      curl -fsSL https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl -o ${kubectl}
      chmod +x ${kubectl}
    END
    creates => $kubectl,
    unless  => "/usr/bin/test -x ${k3s}",
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
