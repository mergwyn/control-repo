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
    location => 'https://pkgs.k8s.io/core:/stable:/v1.31/deb/',
    repos    => ' ',
    release  => '/',
    key      => '/usr/share/keyrings/kubernetes-archive-keyring.gpg',
    include  => { deb => true, src => false },
  }

  # --- Helm repo ---
  file { '/usr/share/keyrings/helm-archive-keyring.gpg':
    ensure  => file,
    source  => 'https://baltocdn.com/helm/signing.asc',
    mode    => '0644',
    require => File['/usr/share/keyrings'],
  }

  apt::source { 'helm':
    location => 'https://baltocdn.com/helm/stable/debian/',
    repos    => 'all',
    release  => '/',
    key      => '/usr/share/keyrings/helm-archive-keyring.gpg',
    include  => { deb => true, src => false },
  }

  # --- ArgoCD repo ---
  file { '/usr/share/keyrings/argocd-archive-keyring.gpg':
    ensure  => file,
    source  => 'https://apt.argoproj.io/key.gpg',
    mode    => '0644',
    require => File['/usr/share/keyrings'],
  }

  apt::source { 'argocd':
    location => 'https://apt.argoproj.io/',
    repos    => 'stable',
    release  => '/',
    key      => '/usr/share/keyrings/argocd-archive-keyring.gpg',
    include  => { deb => true, src => false },
  }

  # --- Base packages (curl removed) ---
  package { [
    'helm',
    'kubectx', # includes kubens
    'sops',
    'age',
    'argocd',
    'kustomize',
    'velero',
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

  # --- Optional binaries like helmfile and cilium-cli ---
  # Make sure these subscribe to apt_update for idempotence
  exec { 'install-helmfile':
    path      => ['/usr/bin', '/bin'],
    creates   => "${bin_dir}/helmfile",
    subscribe => Exec['apt_update'],
    command   => @(HEREDOC)
      curl -fsSL https://github.com/helmfile/helmfile/releases/download/v0.162.0/helmfile_0.162.0_linux_amd64.tar.gz \
      | tar -xz -C ${bin_dir} helmfile
      | HEREDOC
  }

  exec { 'install-cilium-cli':
    path      => ['/usr/bin', '/bin'],
    creates   => "${bin_dir}/cilium",
    subscribe => Exec['apt_update'],
    command   => @(HEREDOC)
      curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz \
      | tar -xz -C ${bin_dir} cilium
      | HEREDOC
  }

}
