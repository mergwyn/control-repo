#
#
class profile::app::lxd::remotes::owner (
  Integer $port = 8443,
) {
  $lxd_hosts = puppetdb_query([
    'from',
    'nodes',
    ['=', ['fact', 'lxd.enabled'], true],
  ])

  # collect all the host certs
  File <<| tag == 'lxd_server_cert' |>>

  $remote_hosts = puppetdb_query([
    'from',
    'nodes',
    ['=', ['fact', 'lxd_remote_owner'], $facts['networking']['fqdn']],
  ]).map |$n| {
    $n['certname']
  }.filter |$h| {
    $h and $h != $facts['networking']['fqdn']
  }

  class { 'profile::app::lxd::remotes':
    remote_hosts => $remote_hosts,
    port         => $port,
  }
}
