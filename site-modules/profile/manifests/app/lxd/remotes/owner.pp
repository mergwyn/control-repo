#
#
class profile::app::lxd::remotes::owner (
  Integer $port = 8443,
) {
  $remote_hosts = puppetdb_query([
    'from',
    'nodes',
    ['=', ['fact', 'lxd.enabled'], true],
  ])
  .map |$n| { $n['certname'] }
  .filter |$h| { $h != $facts['networking']['fqdn'] }

  notice("LXD remote hosts discovered: ${remote_hosts}")

  class { 'profile::app::lxd::remotes':
    remote_hosts => $remote_hosts,
    port         => $port,
  }
}
