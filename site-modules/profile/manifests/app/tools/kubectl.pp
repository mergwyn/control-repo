#
#
class profile::app::tools::kubectl (
  String $version = '1.36.3', # renovate: datasource=github-releases depName=kubernetes/kubernetes
) {
  $bin_dir = '/usr/local/bin'
  $kubectl = "${bin_dir}/kubectl"
  $k3s     = "${bin_dir}/k3s"

  # Only create symlink if kubectl is not already a symlink to k3s
  exec { 'kubectl-symlink-to-k3s':
    command => "/bin/ln -sf ${k3s} ${kubectl}",
    onlyif  => @("END"),
                test -x ${k3s} && (
                  test ! -L ${kubectl} || [ "$(readlink ${kubectl})" != "${k3s}" ]
                )
                | - END
    path    => ['/bin', '/usr/bin'],
  }

  # Install kubectl only if symlink does not exist
  exec { 'install-kubectl':
    command => @("END"),
                sh -c '
                  set -e
                  curl -fsSL https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl -o ${kubectl}
                  chmod +x ${kubectl}
                '
                | - END
    path    => ['/bin', '/usr/bin', $bin_dir],
    require => Exec['kubectl-symlink-to-k3s'],
    unless  => @("END"),
               sh -c '
               if test -L ${kubectl};
               then exit 0;
               elif test -x ${kubectl};
                 then ${kubectl} version --client 2>/dev/null | grep -q ${version};
                 else exit 1;
               fi'
               | - END
  }
}
