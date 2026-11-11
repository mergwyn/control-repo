# @summary Runs Kopia backups on demand via a restricted SSH trigger, replacing cron.daily.
#
# Applied to every node that is backed up (physical hosts and LXC containers).
# Installs a `kopia-backup.service` oneshot unit that wraps the existing backup
# script, creates an unprivileged `kopia-trigger` user whose only permitted action
# is starting that unit, and announces the node to the orchestrator via PuppetDB
# exported resources.
#
# Two things are collected/exported:
#
# * Exported `concat::fragment` (tag `kopia-orchestrator-nodes`): adds this node's
#   FQDN to the orchestrator's nodes file, positioned by `$order`.
# * Collected `ssh_authorized_key` (tag `kopia-trigger-key`): the orchestrator's
#   public key, exported by `profile::app::kopia::orchestrator`.
#
# Prerequisites: PuppetDB with storeconfigs, puppetlabs-concat and puppetlabs-stdlib,
# and `sshd` and `sudo` installed on the node.
#
# @note The orchestrator's key only appears here after the orchestrator has run
#   Puppet twice (the first run generates the keypair, the second exports it via
#   the `kopia_orchestrator_pubkey` fact). Nodes pick it up on their next run.
#
# @note The backup script itself (`$backup_command`) is not managed here. Any
#   existing Puppet resource that creates `$legacy_cron_file` must be removed,
#   otherwise it will conflict with the `ensure => absent` below.
#
# @example Defaults (order 50), assigned via the role/profile
#   include profile::app::kopia::trigger
#
# @example Per-node ordering in hiera (lower runs first)
#   profile::app::kopia::trigger::order: 70
#
# @example Different backup script and longer timeout for a large node
#   profile::app::kopia::trigger::backup_command: '/opt/scripts/bin/kopia-backup'
#   profile::app::kopia::trigger::timeout: '8h'
#
# @param order
#   Position of this node in the orchestrator's run order. Lower values run
#   earlier. Zero-padded to three digits when exported because `concat` sorts
#   fragments as strings.
#
# @param backup_command
#   Absolute path of the script executed by `kopia-backup.service`.
#
# @param timeout
#   systemd `TimeoutStartSec` for the backup unit (e.g. `4h`). The unit is killed
#   and reported as failed if it exceeds this.
#
# @param nodes_file
#   Target path of the orchestrator's nodes file that this node's fragment is
#   exported to. Must match `${config_dir}/nodes` in
#   `profile::app::kopia::orchestrator`.
#
# @param legacy_cron_file
#   The old cron.daily script path, removed by this class.
#
# @param trigger_user
#   Name of the restricted SSH user. Must match `trigger_user` in
#   `profile::app::kopia::orchestrator`.
#
class profile::app::kopia::trigger (
  Integer[0, 999]      $order            = 50,
  Stdlib::Absolutepath $backup_command   = '/opt/scripts/bin/kopia-backup',
  String[1]            $timeout          = '4h',
  Stdlib::Absolutepath $nodes_file       = '/etc/kopia-orchestrator/nodes',
  String[1]            $trigger_user     = 'kopia-trigger',
) {
  $fqdn = $facts['networking']['fqdn']

  # The backup unit. A oneshot that is already running makes a second
  # `systemctl start` wait for it rather than start a duplicate run.
  file { '/etc/systemd/system/kopia-backup.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("UNIT"),
      [Unit]
      Description=Kopia snapshot run
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      Environment=HOME=/root
      ExecStart=${backup_command}
      Nice=10
      IOSchedulingClass=idle
      TimeoutStartSec=${timeout}
      | UNIT
    notify  => Exec['kopia-backup-daemon-reload'],
  }

  exec { 'kopia-backup-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Restricted trigger user: no password, key-only, one sudo rule.
  user { $trigger_user:
    ensure     => present,
    system     => true,
    shell      => '/bin/sh',
    home       => "/var/lib/${trigger_user}",
    managehome => true,
  }

  file { "/etc/sudoers.d/${trigger_user}":
    ensure       => file,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => "${trigger_user} ALL=(root) NOPASSWD: /usr/bin/systemctl start --wait kopia-backup.service\n",
    validate_cmd => '/usr/sbin/visudo -cf %',
  }

  # Orchestrator's public key, exported by profile::app::kopia::orchestrator.
  # The exported resource carries the restrict/from/command options.
  Ssh_authorized_key <<| tag == 'kopia-trigger-key' |>> {
    require => User[$trigger_user],
  }

  # Announce this node to the orchestrator.
  @@concat::fragment { "kopia-node-${fqdn}":
    tag     => 'kopia-orchestrator-nodes',
    target  => $nodes_file,
    order   => sprintf('%03d', $order),
    content => "${fqdn}\n",
  }
}
