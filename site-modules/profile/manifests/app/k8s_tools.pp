#
#
class profile::app::k8s_tools (
  Array[String] $packages,
  String $wakemeops_url,
) {
  # --- OS Specific Setup ---
  if $facts['os']['name'] == 'Ubuntu' {
    include apt

    apt::source { 'wakemeops':
      location => $wakemeops_url,
      release  => 'stable',
      repos    => 'main',
      key      => {
        'id'     => '1BB92A36984328BD65B79AA56402434E01F82B33',
        'source' => 'https://docs.wakemeops.com',
      },
      include  => { 'src' => false },
    }

    # Use K3s as kubectl if present, otherwise install standalone
    if find_file('/usr/local/bin/k3s') {
      file { '/usr/local/bin/kubectl':
        ensure => 'link',
        target => '/usr/local/bin/k3s',
      }
    } else {
      package { 'kubectl':
        ensure  => latest,
        require => Apt::Source['wakemeops'],
      }
    }

    # Default package settings for Ubuntu
    Package {
      ensure  => latest,
      require => Apt::Source['wakemeops'],
    }
  } elsif $facts['os']['family'] == 'Darwin' {
    # macOS - Provider must be explicitly set to 'brew'
    Package {
      ensure   => latest,
      provider => 'brew',
    }
    package { 'kubectl': }
  }

  # --- General Package Installation ---
  package { $packages: }

  # --- Helm Secrets Plugin (Wrapped to avoid interface/URL splitting) ---
  $helm_secrets_cmd = @(CMD/L)
    /usr/local/bin/helm plugin install \
    https://github.com/jkroepke/helm-secrets
    | CMD

  exec { 'install_helm_secrets':
    command => $helm_secrets_cmd,
    unless  => '/usr/local/bin/helm plugin list | grep -q secrets',
    path    => ['/usr/local/bin', '/usr/bin', '/bin'],
    require => Package['helm'],
  }
}
