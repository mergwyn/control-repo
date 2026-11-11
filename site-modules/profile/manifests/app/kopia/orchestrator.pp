# @summary Runs Kopia backups across all nodes in sequence from a single host.
#
# Applied to exactly one node. Every night a systemd timer starts
# `kopia-orchestrator.service`, which walks the nodes file in order and runs
# `kopia-backup.service` on each node over SSH, one at a time.
#
# Everything is driven from PuppetDB:
#
# * The nodes file is assembled from `concat::fragment` resources exported by
#   `profile::app::kopia::trigger` (tag `kopia-orchestrator-nodes`).
# * The orchestrator generates its own SSH keypair and exports the public half as
#   an `ssh_authorized_key` (tag `kopia-trigger-key`) restricted to this host's
#   IP and to the single backup command. No private key is stored in hiera/eyaml.
#
# Prerequisites: PuppetDB with storeconfigs, puppetlabs-concat and puppetlabs-stdlib,
# the `kopia_orchestrator_pubkey` custom fact (lib/facter), and the script
# `files/kopia-orchestrator.sh` in the profile module. The directory containing
# `$script_path` is assumed to be managed elsewhere (it is not declared here).
#
# @note Bootstrap takes two Puppet runs on this node: the first generates the
#   keypair, the second exports the public key (the fact only appears once the key
#   exists). Trigger nodes then collect it on their next run.
#
# @note If this node is also a backup target (include the trigger class as well),
#   the loopback addresses in `$from_extra` allow it to SSH to itself.
#
# @example Basic usage
#   include profile::app::kopia::orchestrator
#
# @example Different schedule and a longer per-node limit (hiera)
#   profile::app::kopia::orchestrator::on_calendar: '*-*-* 01:30:00'
#   profile::app::kopia::orchestrator::per_node_timeout: '6h'
#
# @param config_dir
#   Directory holding the nodes file and the SSH keypair (mode 0700).
#
# @param state_dir
#   Directory for run state: the orchestrator lock, per-node `last_ok.*` stamps
#   and the `last_full_success` heartbeat used for monitoring.
#
# @param script_path
#   Where the orchestrator script is installed.
#
# @param on_calendar
#   systemd `OnCalendar` expression for the nightly run.
#
# @param per_node_timeout
#   Maximum time to wait for one node before it is recorded as failed. Passed to
#   the script as `PER_NODE_TIMEOUT` (coreutils `timeout` syntax).
#
# @param total_timeout
#   systemd `TimeoutStartSec` for the whole orchestrator run.
#
# @param trigger_user
#   Name of the restricted SSH user on each node. Must match `trigger_user` in
#   `profile::app::kopia::trigger`.
#
# @param from_extra
#   Additional source addresses allowed in the exported key's `from=` option,
#   alongside this host's primary IP.
#
# @param collect_host_keys
#   When true, collect all exported `sshkey` resources so the orchestrator can use
#   `StrictHostKeyChecking=yes`. Leave false if host keys are already distributed
#   to this node by another class.
#
class profile::app::kopia::orchestrator (
  Stdlib::Absolutepath $config_dir        = '/etc/kopia-orchestrator',
  Stdlib::Absolutepath $state_dir         = '/var/lib/kopia-orchestrator',
  Stdlib::Absolutepath $script_path       = '/opt/scripts/bin/kopia-orchestrator',
  String[1]            $on_calendar       = '*-*-* 00:05:00',
  String[1]            $per_node_timeout  = '4h',
  String[1]            $total_timeout     = '12h',
  String[1]            $trigger_user      = 'kopia-trigger',
  Array[String[1]]     $from_extra        = ['127.0.0.1', '::1'],
  Boolean              $collect_host_keys = false,
) {
  $fqdn = $facts['networking']['fqdn']
  $from = join(concat([$facts['networking']['ip']], $from_extra), ',')

  file { [$config_dir, $state_dir]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # Nodes file, built from fragments exported by the trigger class.
  concat { "${config_dir}/nodes":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => File[$config_dir],
  }
  Concat::Fragment <<| tag == 'kopia-orchestrator-nodes' |>>

  # Keypair is generated locally; the private key never leaves this host.
  exec { 'kopia-orchestrator-keygen':
    command => "/usr/bin/ssh-keygen -q -t ed25519 -N '' -C kopia-orchestrator@${fqdn} -f ${config_dir}/id_ed25519",
    creates => "${config_dir}/id_ed25519",
    require => File[$config_dir],
  }

  # Export the public key. The fact is absent until the keypair exists.
  if $facts['kopia_orchestrator_pubkey'] {
    @@ssh_authorized_key { "kopia-trigger@${fqdn}":
      ensure  => present,
      user    => $trigger_user,
      type    => $facts['kopia_orchestrator_pubkey']['type'],
      key     => $facts['kopia_orchestrator_pubkey']['key'],
      options => [
        'restrict',
        "from=\"${from}\"",
        'command="/usr/bin/sudo /usr/bin/systemctl start --wait kopia-backup.service"',
      ],
      tag     => 'kopia-trigger-key',
    }
  }

  if $collect_host_keys {
    Sshkey <<| |>>
  }

  file { '/etc/systemd/system/kopia-orchestrator.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("UNIT"),
      [Unit]
      Description=Sequential Kopia backups across nodes
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      Environment=NODES_FILE=${config_dir}/nodes
      Environment=SSH_KEY=${config_dir}/id_ed25519
      Environment=STATUS_DIR=${state_dir}
      Environment=PER_NODE_TIMEOUT=${per_node_timeout}
      Environment=TRIGGER_USER=${trigger_user}
      ExecStart=${script_path}
      TimeoutStartSec=${total_timeout}
      | UNIT
    require => File[$state_dir],
    notify  => Exec['kopia-orchestrator-daemon-reload'],
  }

  file { '/etc/systemd/system/kopia-orchestrator.timer':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("UNIT"),
      [Unit]
      Description=Nightly Kopia orchestration

      [Timer]
      OnCalendar=${on_calendar}
      Persistent=true

      [Install]
      WantedBy=timers.target
      | UNIT
    notify  => Exec['kopia-orchestrator-daemon-reload'],
  }

  exec { 'kopia-orchestrator-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  service { 'kopia-orchestrator.timer':
    ensure  => running,
    enable  => true,
    require => Exec['kopia-orchestrator-daemon-reload'],
  }
}
