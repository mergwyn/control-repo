# @summary
#   Expose OpenVox agent health metrics to Prometheus.
#
# @description
#   Parses the OpenVox last_run_summary.yaml file and writes metrics
#   for consumption by the node_exporter textfile collector.
#
#   The metrics are updated periodically using a systemd timer.
#
# @example
#   include profile::openvox::monitoring
#
class profile::openvox::monitoring {
  include profile::app::monitoring::node_exporter

  $summary_file = '/opt/puppetlabs/puppet/public/last_run_summary.yaml'
  $script       = '/usr/local/sbin/openvox-prometheus'
  $metrics_file = '/var/lib/node_exporter/textfile_collector/openvox.prom'

  file { $script:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('profile/openvox-prometheus.epp', {
      summary_file => $summary_file,
      metrics_file => $metrics_file,
    }),
  }

  $_timer = @("EOT")
    [Timer]
    OnBootSec=5min
    OnUnitActiveSec=5min

    [Install]
    WantedBy=timers.target
    | EOT

  $_service = @("EOT")
    [Service]
    Type=oneshot
    User=root
    ExecStart=${script}

    [Install]
    WantedBy=multi-user.target
    | EOT

  systemd::timer { 'openvox-prometheus.timer':
    ensure          => present,
    active          => true,
    enable          => true,
    timer_content   => $_timer,
    service_content => $_service,
    require         => File[$script],
  }
}
