#
#
class profile::app::k8s_tools::debian {
  $bin_dir = '/usr/local/bin'
  $has_k3s = file_exists('/usr/local/bin/k3s')

  include apt

  # --- Kubernetes key & repo ---
  apt::key { 'kubernetes':
    id     => '8D81803C0EBFCD88',
    source => 'https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key',
  }

  apt::source { 'kubernetes':
    location => 'https://pkgs.k8s.io/core:/stable:/v1.31/deb/',
    release  => '/',
    repos    => ' ',
    require  => Apt::Key['kubernetes'],
  }

  # --- Helm key & repo ---
  apt::key { 'helm':
    id     => 'B1998361219BD9C9',
    source => 'https://baltocdn.com/helm/signing.asc',
  }

  apt::source { 'helm':
    location => 'https://baltocdn.com/helm/stable/debian/',
    repos    => 'all',
    require  => Apt::Key['helm'],
  }

  # --- ArgoCD key & repo ---
  apt::key { 'argocd':
    id     => '7F2DF7AD',
    source => 'https://apt.argoproj.io/key.gpg',
  }

  apt::source { 'argocd':
    location => 'https://apt.argoproj.io/',
    repos    => 'stable',
    require  => Apt::Key['argocd'],
  }

  # --- Base packages ---
  package { [
    'helm',
    'kubectx', # includes kubens
    'sops',
    'age',
    'argocd',
    'kustomize',
    'velero',
  ]:
    ensure  => latest,
    require => Exec['apt_update'],
  }

  # --- kubectl (k3s-aware) ---
  if $has_k3s {
    package { 'kubectl': ensure => absent }

    file { "${bin_dir}/kubectl":
      ensure => link,
      target => "${bin_dir}/k3s",
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  } else {
    package { 'kubectl':
      ensure  => latest,
      require => Exec['apt_update'],
    }
  }
}
