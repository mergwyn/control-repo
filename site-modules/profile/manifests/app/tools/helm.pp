# Class: profile::app::tools::helm
#
# Manages Helm CLI and required plugins system-wide for all users
#
class profile::app::tools::helm (
  String $version         = '4.2.4',                      # renovate: datasource=github-releases depName=helm/helm
  String $secrets_version = '4.7.6',                      # renovate: datasource=github-releases depName=jkroepke/helm-secrets
  String $diff_version    = 'v3.15.7',                     # renovate: datasource=github-releases depName=databus23/helm-diff
  String $plugin_dir      = '/usr/local/share/helm/plugins',
) {
  # 1. Install Helm Binary
  profile::app::binary_install { 'helm':
    version         => $version,
    binary          => 'helm',
    url             => "https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz",
    archive         => 'tar.gz',
    archive_extract => 'linux-amd64/helm',
    version_cmd     => 'helm version --short',
  }

  # 2. Export HELM_PLUGINS System-Wide for All Non-Root Users
  file { '/etc/profile.d/helm.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "export HELM_PLUGINS=\"${plugin_dir}\"\n",
  }

  # 3. Ensure Shared Plugin Directory Structure Exists
  file { ['/usr/local/share/helm', $plugin_dir, "${plugin_dir}/helm-diff"]:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Profile::App::Binary_install['helm'],
  }

  # 4. Download & Extract helm-secrets Plugins
  # 4.1. Ensure all 3 plugin directories exist
    $secrets_plugins = [
      "${plugin_dir}/secrets",
      "${plugin_dir}/secrets-getter",
      "${plugin_dir}/secrets-post-renderer",
    ]

    file { $secrets_plugins:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$plugin_dir],
    }

    # 4.2. Extract helm-secrets archive into all three plugin folders
    $secrets_plugins.each |String $dir| {
      archive { "${dir}/secrets.tar.gz":
        ensure       => present,
        source       => "https://github.com/jkroepke/helm-secrets/releases/download/v${secrets_version}/helm-secrets.tar.gz",
        extract      => true,
        extract_path => $dir,
        creates      => "${dir}/scripts",
        cleanup      => true,
        require      => File[$dir],
      }
    }

    # 4.3. Set up plugin.yaml for secrets-getter
    file { "${plugin_dir}/secrets-getter/plugin.yaml":
      ensure  => file,
      source  => "${plugin_dir}/secrets-getter/plugin.getter.yaml",
      require => Archive["${plugin_dir}/secrets-getter/secrets.tar.gz"],
    }

    # 4.4. Set up plugin.yaml for secrets-post-renderer
    file { "${plugin_dir}/secrets-post-renderer/plugin.yaml":
      ensure  => file,
      source  => "${plugin_dir}/secrets-post-renderer/plugin.post-renderer.yaml",
      require => Archive["${plugin_dir}/secrets-post-renderer/secrets.tar.gz"],
    }

  # 5. Download & Extract helm-diff Plugin
  archive { "${plugin_dir}/helm-diff.tgz":
    ensure       => present,
    source       => "https://github.com/databus23/helm-diff/releases/download/${diff_version}/helm-diff-linux-amd64.tgz",
    extract      => true,
    extract_path => "${plugin_dir}/helm-diff",
    creates      => "${plugin_dir}/helm-diff/diff/plugin.yaml",
    cleanup      => true,
    require      => File["${plugin_dir}/helm-diff"],
  }
}
