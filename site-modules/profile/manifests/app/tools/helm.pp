# Class: profile::app::tools::helm
#
# Manages Helm CLI and required plugins system-wide for all users
#
class profile::app::tools::helm (
  String $version         = '4.2.4',                      # renovate: datasource=github-releases depName=helm/helm
  String $secrets_version = '4.7.7',                      # renovate: datasource=github-releases depName=jkroepke/helm-secrets
  String $diff_version    = 'v3.15.11',                     # renovate: datasource=github-releases depName=databus23/helm-diff
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

  # 2. Clean Up Legacy Root Plugin Directory
  file { '/root/.local/share/helm/plugins':
    ensure  => absent,
    force   => true,
    recurse => true,
  }

  # 3. Export HELM_PLUGINS System-Wide for All Users
  file { '/etc/profile.d/helm.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "export HELM_PLUGINS=\"${plugin_dir}\"\n",
  }

  # 4. Ensure Shared Plugin Directory Exists
  file { ['/usr/local/share/helm', $plugin_dir]:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Profile::App::Binary_install['helm'],
  }

  # 5. Install / Upgrade helm-secrets Components via OCI
  $secrets_plugins = ['secrets', 'secrets-getter', 'secrets-post-renderer']

  $secrets_plugins.each |String $plugin| {
    exec { "install_${plugin}":
      command     => "/usr/local/bin/helm plugin uninstall ${plugin} 2>/dev/null; /usr/local/bin/helm plugin install oci://ghcr.io/jkroepke/helm-secrets/${plugin}:${secrets_version} --verify=false",
      unless      => "grep -qE 'version: \"?${secrets_version}\"?' ${plugin_dir}/${plugin}/plugin.yaml 2>/dev/null",
      environment => ["HELM_PLUGINS=${plugin_dir}"],
      path        => ['/usr/local/bin', '/usr/bin', '/bin'],
      require     => File[$plugin_dir],
    }
  }

  # 6. Install / Upgrade helm-diff via Git URL
  $clean_diff_version = regsubst($diff_version, '^v', '')

  exec { 'install_helm_diff':
    command     => "/usr/local/bin/helm plugin uninstall diff 2>/dev/null; /usr/local/bin/helm plugin install https://github.com/databus23/helm-diff --version ${diff_version} --verify=false",
    unless      => "grep -qE 'version: \"?${clean_diff_version}\"?' ${plugin_dir}/helm-diff/diff/plugin.yaml 2>/dev/null || grep -qE 'version: \"?${clean_diff_version}\"?' ${plugin_dir}/helm-diff/plugin.yaml 2>/dev/null",
    environment => ["HELM_PLUGINS=${plugin_dir}"],
    path        => ['/usr/local/bin', '/usr/bin', '/bin'],
    require     => File[$plugin_dir],
  }
}
