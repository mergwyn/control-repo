# @summary
#   Manage the node_exporter textfile collector directory.
#
# @description
#   Creates the directory used by node_exporter's textfile collector.
#   The directory may be consumed by a host-installed node_exporter or
#   mounted into a Kubernetes-managed node_exporter.
#
class profile::app::monitoring::node_exporter_textfile {
  file { '/var/lib/node_exporter':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/var/lib/node_exporter/textfile_collector':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/var/lib/node_exporter'],
  }
}
