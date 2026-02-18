#
#
class profile::app::k8s_tools::debian {
  $bin_dir = '/usr/local/bin'

  include apt

  # --- Ensure keyring directory exists ---
  file { '/usr/share/keyrings':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # --- Kubernetes repo ---
  file { '/usr/share/keyrings/kubernetes-archive-keyring.gpg':
    ensure  => file,
    source  => 'https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key',
    mode    => '0644',
    require => File['/usr/share/keyrings'],
  }

  apt::source { 'kubernetes':
    source_format => 'sources',
    location      => 'https://pkgs.k8s.io/core:/stable:/v1.31/deb/',
    repos         => ' ',
    release       => '/',
    keyring       => '/usr/share/keyrings/kubernetes-archive-keyring.gpg',
    include       => { deb => true, src => false },
  }

  # --- Helm repo ---
  file { '/usr/share/keyrings/helm.gpg':
    ensure  => file,
    source  => 'https://packages.buildkite.com/helm-linux/helm-debian/gpgkey',
    mode    => '0644',
    require => File['/usr/share/keyrings'],
  }

  apt::source { 'helm':
    source_format => 'sources',
    location      => 'https://packages.buildkite.com/helm-linux/helm-debian/any/',
    repos         => 'main',
    release       => 'any',
    keyring       => '/usr/share/keyrings/helm.gpg',
    include       => { deb => true, src => false },
  }

  # --- Base packages (curl removed) ---
  package { [
    'helm',
    'kubectx', # includes kubens
  ]:
    ensure    => latest,
    require   => Apt::Source['kubernetes'],
    subscribe => Exec['apt_update'],
  }

  # --- k3s-aware kubectl ---
  exec { 'symlink-kubectl-to-k3s':
    command => "/bin/ln -sf ${bin_dir}/k3s ${bin_dir}/kubectl",
    creates => "${bin_dir}/kubectl",
    onlyif  => "/usr/bin/test -f ${bin_dir}/k3s",
    path    => ['/bin', '/usr/bin'],
  }

  package { 'kubectl':
    ensure  => latest,
    require => Exec['apt_update'],
  }
}
