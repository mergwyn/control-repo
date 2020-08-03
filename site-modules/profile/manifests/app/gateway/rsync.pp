# @summary manage letsencrypt certificates

class profile::app::gateway::rsync {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  # TODO pass path in as parameter?
  $base = '/etc/letsencrypt/live/'
  rsync::server::module { 'cert':
    path           => $base,
    incoming_chmod => false,
    outgoing_chmod => false,
    hosts_allow    => [ '192.168.11.0/16' ],
    hosts_deny     => [ '*' ],
    list           => 'true',
    use_chroot     => 'no',
    require        => File[$base],
  }

}
