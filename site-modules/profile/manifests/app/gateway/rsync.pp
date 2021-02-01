# @summary manage letsencrypt certificates

class profile::app::gateway::rsync {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  class { 'rsync::server': }

  # TODO pass path in as parameter?
  $base = '/etc/letsencrypt/live/'

  rsync::server::module { 'cert':
    path           => $base,
    incoming_chmod => false,
    outgoing_chmod => false,
    hosts_allow    => [ "${facts['networking']['os']}/${lookup('defaults::bits')}" ],
    hosts_deny     => [ '*' ],
    list           => 'true',
    use_chroot     => 'no',
    require        => File[$base],
  }

}
