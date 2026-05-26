# profile/manifests/app/monitoring/node-exporter.pp
class profile::app::node_exporter (
    Stdlib::Port   $port             = 9100,
  ) {
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
        ARGS="--web.listen-address=:${port}"
        | EOT
      notify  => Service['prometheus-node-exporter'],
    }

    service { 'prometheus-node-exporter':
      ensure  => running,
      enable  => true,
      require => Package['prometheus-node-exporter'],
    }  }
