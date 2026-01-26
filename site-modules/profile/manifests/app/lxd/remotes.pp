#
class profile::app::lxd::remotes (
  Array[Hash] $remote_hosts,
  Integer     $port = 8443,
) {
  if $remote_hosts.empty {
    notice('No LXD remotes to configure')
  } else {
    $remote_hosts.each |Hash $host| {
      exec { "lxd-add-remote-${host['name']}":
        path      => '/usr/bin:/usr/sbin:/bin:/sbin',
        command   => "lxc remote add ${host['name']} https://${host['fqdn']}:${port} --accept-certificate",
        unless    => "lxc remote list --format csv | cut -d, -f1 | grep -qx ${host['name']}",
        onlyif    => "test -f /var/lib/lxd-certs/${host['fqdn']}.crt",
        tries     => 5,
        try_sleep => 10,
        require   => Package['lxd'],
      }
    }
  }
}
