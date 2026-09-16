# @summary Installs and registers a GitHub Actions self-hosted runner
#
# Downloads the runner tarball, registers it against a single repo, and
# installs it as a systemd service via the runner's own svc.sh wrapper.
# Registration tokens expire after one hour, so a fresh one is fetched on
# every Puppet run via the GitHub API — but config.sh only actually runs
# if the runner isn't registered yet (.runner file absent), so this is
# safe to apply repeatedly.
#
# @param github_pat
#   A GitHub Personal Access Token with `repo` scope (classic) or
#   Administration:Read-and-write (fine-grained), used only to mint a
#   short-lived runner registration token via the API. Store via eyaml.
# @param repo
#   The `owner/name` of the repo this runner registers against.
# @param version
#   Runner release version to install. Check
#   https://github.com/actions/runner/releases for the current one —
#   Renovate can track this via a regexManager if you want it automated.
# @param install_dir
#   Where the runner is unpacked and run from.
# @param runner_user
#   System user the runner process runs as.
# @param labels
#   Extra labels beyond the automatic self-hosted/OS/arch ones. Not
#   required for `runs-on: self-hosted` to match, but useful if you ever
#   run runners on more than one node and want to target this one
#   specifically.
#
class profile::app::github_actions_runner (
  String[1]            $github_pat  = lookup('secrets::github_token'),
  String               $repo        = 'mergwyn/cluster-gitops',
  # renovate: datasource=github-releases depName=actions/runner
  String               $version     = '2.319.1',
  Stdlib::Absolutepath $install_dir = '/opt/actions-runner',
  String               $runner_user = 'github-runner',
  Array[String]        $labels      = [],
) {
  $label_arg = $labels.empty ? {
    true    => '',
    default => "--labels ${labels.join(',')}",
  }
  user { $runner_user:
    ensure     => present,
    system     => true,
    home       => $install_dir,
    managehome => true,
    shell      => '/usr/sbin/nologin',
  }

  file { "${install_dir}/.env":
    ensure  => file,
    owner   => $runner_user,
    group   => $runner_user,
    mode    => '0640',
    content => "HELM_PLUGINS=/usr/local/share/helm/plugins\n",
    require => Exec['extract-actions-runner'],
  }

  ~> exec { 'restart-actions-runner-service':
    command     => "/bin/systemctl restart $(/bin/systemctl list-unit-files --type=service | /bin/grep -o 'actions\.runner\.[^ ]*\.service' | /usr/bin/head -1)",
    refreshonly => true,
  }

  $tarball = "${install_dir}/actions-runner-linux-x64-${version}.tar.gz"

  # Atomic download: write to a temp file then move, per the
  # curl-into-running-binary lesson from the NTP/acme.sh work.
  exec { 'download-actions-runner':
    command => "/usr/bin/curl -fsSL -o ${tarball}.tmp https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-x64-${version}.tar.gz && /bin/mv ${tarball}.tmp ${tarball}",
    creates => $tarball,
    user    => $runner_user,
    path    => ['/usr/bin', '/bin'],
    require => File[$install_dir],
  }

  -> exec { 'extract-actions-runner':
    command => "/bin/tar xzf ${tarball} -C ${install_dir}",
    creates => "${install_dir}/config.sh",
    user    => $runner_user,
  }

  # Mint a fresh registration token every run; harmless if unused since
  # configure-actions-runner below only fires when .runner is absent.
  -> exec { 'get-runner-registration-token':
    command => "/usr/bin/curl -fsSL -X POST -H 'Authorization: token ${github_pat.unwrap}' -H 'Accept: application/vnd.github+json' https://api.github.com/repos/${repo}/actions/runners/registration-token | /usr/bin/jq -r .token > ${install_dir}/.reg_token",
    user    => $runner_user,
    path    => ['/usr/bin', '/bin'],
  }

  -> exec { 'configure-actions-runner':
    command     => "${install_dir}/config.sh --url https://github.com/${repo} --token $(cat ${install_dir}/.reg_token) --name ${trusted['certname']} ${label_arg} --work _work --unattended --replace",
    cwd         => $install_dir,
    creates     => "${install_dir}/.runner",
    user        => $runner_user,
    environment => ["HOME=${install_dir}"],
  }

  # Registration token is single-use and short-lived; no reason to leave
  # it on disk once config.sh has consumed it.
  -> file { "${install_dir}/.reg_token":
    ensure => absent,
  }

  ~> exec { 'install-actions-runner-service':
    command => "${install_dir}/svc.sh install ${runner_user}",
    cwd     => $install_dir,
    unless  => '/usr/bin/systemctl list-unit-files | /bin/grep -q actions.runner',
  }

  -> exec { 'start-actions-runner-service':
    command => "/bin/systemctl start $(/bin/systemctl list-unit-files --type=service | /bin/grep -o 'actions\.runner\.[^ ]*\.service' | /usr/bin/head -1)",
    unless  => "/bin/systemctl is-active --quiet $(/bin/systemctl list-unit-files --type=service | /bin/grep -o 'actions\.runner\.[^ ]*\.service' | /usr/bin/head -1)",
  }


}
