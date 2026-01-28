#
class profile::app::lxd::remotes (
  Array[Hash] $remote_hosts,
  Integer     $port = 8443,
) {
  require profile::platform::baseline::debian::virtual::lxd

  if $remote_hosts.empty {
    notice('No LXD remotes to configure')
  } else {

    $remote_hosts.each |Hash $host| {
      exec { "lxd-add-remote-${host['name']}":
        path    => ['/usr/sbin', '/usr/bin'],
        command => "/usr/sbin/lxc remote add ${host['name']} https://${host['fqdn']}:${port} --accept-certificate",
        unless  => "/usr/sbin/lxc remote list --format csv | cut -d, -f1 | grep -qx ${host['name']}",
        timeout => 60,
        require => Package['lxd'],
      }

    }
  }
}
