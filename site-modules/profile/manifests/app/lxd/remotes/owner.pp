#
class profile::app::lxd::remotes::owner {
  $port = 8443

  $nodes = pick(
    puppetdb_query([
      'from', 'nodes',
      [
        'and',
        ['=', ['fact', 'lxd.enabled'], true],
        ['=', 'node_state', 'active'],
        ['=', 'facts_environment', $environment],
      ]
    ]),
    []
  )

$remote_hosts = $nodes
  .filter |$n| { $n['certname'] =~ String }
  .map |$n| {
    $fqdn  = $n['certname'];
    $short = $fqdn.split(/\./)[0]; {
      'name' => $short,
      'fqdn' => $fqdn,
    }
  }
  .filter |$h| {
    $h['fqdn'] != $facts['networking']['fqdn']
  }

  class { 'profile::app::lxd::remotes':
    remote_hosts => $remote_hosts,
    port         => $port,
  }
}
