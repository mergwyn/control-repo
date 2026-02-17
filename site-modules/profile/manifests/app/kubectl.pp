#
#
class profile::app::kubectl (
  String $version = '0.35.1',
) {
  $bin_dir = '/usr/local/bin'
  $kubectl = "${bin_dir}/kubectl"
  $k3s     = "${bin_dir}/k3s"

  # Only create symlink if k3s exists
  exec { 'kubectl-symlink-to-k3s':
    command => "/bin/ln -sf ${k3s} ${kubectl}",
    onlyif  => "/usr/bin/test -x ${k3s}",
    path    => ['/bin', '/usr/bin'],
  }

  # Install kubectl only if symlink doesn't exist
  exec { 'install-kubectl':
    command => "curl -fsSL https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl -o ${kubectl} && chmod +x ${kubectl}",
    path    => ['/bin', '/usr/bin', $bin_dir],
    unless  => "${kubectl} version --client --short | grep -q ${version}",
    require => Exec['kubectl-symlink-to-k3s'],
  }
}
