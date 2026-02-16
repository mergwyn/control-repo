#
#
class profile::app::k8s_tools::debian {
  $bin_dir = '/usr/local/bin'

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
    'curl',
  ]:
    ensure    => latest,
    require   => Apt::Source['kubernetes'],  # ensures repo exists
    subscribe => Exec['apt_update'],       # updates after apt update
  }

  # --- kubectl (k3s-aware) ---
  file { "${bin_dir}/kubectl":
    ensure => link,
    target => "${bin_dir}/k3s",
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    onlyif => '/usr/bin/test -f /usr/local/bin/k3s',
  }

  package { 'kubectl':
    ensure  => latest,
    require => Exec['apt_update'],
    unless  => '/usr/bin/test -f /usr/local/bin/k3s',
  }
}
