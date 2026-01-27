#
#
class profile::app::lxd::remotes::owner (
  Integer $port = 8443,
) {
  $nodes = pick(
    puppetdb_query([
      'from', 'nodes',
      ['in', 'certname',
        ['from', 'facts',
          ['and',
            ['=', 'name', 'lxd.enabled'],
            ['=', 'value', true],
          ]
        ]
      ]
    ]),
    []
  )

  $remote_hosts = ($nodes)
    .filter |$n| { $n['certname'] }
    .map |$n| {
      $fqdn  = $n['certname'];
      $short = $fqdn.split('.')[0]; {
        'name' => $short,
        'fqdn' => $fqdn,
      }
    }
    .filter |$h| {
      $h['fqdn'] != $facts['networking']['fqdn']
    }

  notice("LXD remote hosts discovered: ${remote_hosts}")

  class { 'profile::app::lxd::remotes':
    remote_hosts => $remote_hosts,
    port         => $port,
  }
}
