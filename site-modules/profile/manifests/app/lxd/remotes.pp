#
#
class profile::app::lxd::remotes (
  Array[String] $remote_hosts,
  Integer       $port = 8443,
) {
  if $remote_hosts.empty {
    notice('No LXD remotes to configure')
  } else {
    $remote_hosts.each |String $host| {
      exec { "lxd-trust-cert-${host}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "lxc config trust add /var/lib/lxd-certs/${host}.crt",
        unless  => "lxc config trust list --format csv | grep -q ${host}",
        require => Package['lxd'],
      }
      exec { "lxd-add-remote-${host}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "lxc remote add ${host} https://${host}:${port} --accept-certificate",
        unless  => "lxc remote list --format csv | cut -d, -f1 | grep -qx ${host}",
        require => Exec["lxd-trust-cert-${host}"],
      }
    }
  }
}
