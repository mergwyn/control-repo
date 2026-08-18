# profile/manifests/app/monitoring/node_exporter.pp
#
# @summary
#   Install and manage Prometheus node_exporter.
#
# @param port
#   Port on which node_exporter listens.
#
class profile::app::monitoring::node_exporter (
  Stdlib::Port $port = 9100,
) {
  include profile::app::monitoring::node_exporter_textfile

  package { 'prometheus-node-exporter':
    ensure => installed,
  }

  file { '/etc/default/prometheus-node-exporter':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("EOT"),
      # Managed by Puppet - do not edit
      ARGS="--web.listen-address=:${port} --collector.textfile.directory=/var/lib/node_exporter/textfile_collector"
      | EOT
    notify  => Service['prometheus-node-exporter'],
  }

  service { 'prometheus-node-exporter':
    ensure  => running,
    enable  => true,
    require => [
      Package['prometheus-node-exporter'],
      File['/var/lib/node_exporter/textfile_collector'],
    ],
  }
}
