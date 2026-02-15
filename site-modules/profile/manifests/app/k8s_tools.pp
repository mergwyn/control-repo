#
#
class profile::app::k8s_tools (
  Array[String] $packages = ['age', 'curl', 'kustomize', 'velero', 'kube-ps1'],
) {
  $bin_dir = '/usr/local/bin'

  if $facts['os']['name'] == 'Ubuntu' {
    include apt

    # --- 1. Kubernetes Repository (Stable Segmented URL) ---
    $k_dom  = 'https://pkgs.k8s.io'
    $k_path = '/core:/stable:/v1.31/deb/'
    $k_url  = "${k_dom}${k_path}"

    file { '/usr/share/keyrings/kubernetes.gpg':
      ensure => file,
      source => "${k_url}Release.key",
    }

    apt::source { 'kubernetes':
      location => $k_url,
      release  => '/',
      repos    => ' ',
      keyring  => '/usr/share/keyrings/kubernetes.gpg',
      require  => File['/usr/share/keyrings/kubernetes.gpg'],
    }

    exec { 'force-k8s-update':
      command     => '/usr/bin/apt-get update',
      subscribe   => Apt::Source['kubernetes'],
      refreshonly => true,
    }

    # --- 2. Kubectl Management (K3s Detection) ---
    # Try to link kubectl to k3s ONLY if k3s actually exists on this node
    # We use a simple test command to see if k3s is there
    file { "${bin_dir}/kubectl":
      ensure => 'link',
      target => '/usr/local/bin/k3s',
      force  => true,
    }

    # --- 3. Binary Tools (Safely Segmented for Safari/UI) ---
    $gh_dom  = 'https://github.com'
    $raw_dom = 'https://raw.githubusercontent.com'

    # Tool Paths
    $s_p   = '/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.amd64'
    $a_p   = '/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64'
    $hf_p  = '/helmfile/helmfile/releases/download/v0.162.0/helmfile_0.162.0_linux_amd64.tar.gz'
    $ctx_p = '/ahmetb/kubectx/master/kubectx'
    $ns_p  = '/ahmetb/kubectx/master/kubens'

    file { "${bin_dir}/sops":
      ensure => file,
      source => "${gh_dom}${s_p}",
      mode   => '0755',
    }

    file { "${bin_dir}/argocd":
      ensure => file,
      source => "${gh_dom}${a_p}",
      mode   => '0755',
    }

    # Helmfile - Use the official installer script
    exec { 'install_helmfile':
      command => "/usr/bin/curl -fsSL ${gh_dom}${hf_p} | /usr/bin/tar -xz -C ${bin_dir} helmfile",
      unless  => "/usr/bin/test -f ${bin_dir}/helmfile",
      path    => ['/usr/bin', '/bin', '/usr/local/bin'],
      require => Package['curl'],
    }

    file { "${bin_dir}/kubectx":
      ensure => file,
      source => "${raw_dom}${ctx_p}",
      mode   => '0755',
    }

    file { "${bin_dir}/kubens":
      ensure => file,
      source => "${raw_dom}${ns_p}",
      mode   => '0755',
    }

    # --- 4. Helm & Secrets ---
    $h_dom  = 'https://raw.githubusercontent.com'
    $h_path = '/helm/helm/main/scripts/get-helm-3'

    exec { 'install_helm':
      command => "/usr/bin/curl -fsSL ${h_dom}${h_path} | /usr/bin/bash",
      creates => "${bin_dir}/helm",
      require => Package['curl'],
    }

    exec { 'install_helm_secrets':
      command => "${bin_dir}/helm plugin install https://github.com",
      unless  => "${bin_dir}/helm plugin list | grep -q secrets",
      path    => [$bin_dir, '/usr/bin', '/bin'],
      require => Exec['install_helm'],
    }

    # --- 5. Final APT Packages ---
    package { $packages: ensure => latest }
  } elsif $facts['os']['family'] == 'Darwin' {
    # --- macOS / Darwin (Homebrew) ---
    Package {
      ensure   => latest,
      provider => 'brew',
    }
    package { ['kubectl', 'helm', 'sops', 'age', 'argocd', 'kubectx', 'kubens', 'helmfile']: }
  }
}
