#
#
class profile::app::ddclient (
  Array[Stdlib::Fqdn] $servers = [ $trusted['hostname'] ],
) {

  class { 'ddclient':
    hosts_config    => 'concat',
    daemon_interval => 300,
    getip_from      => 'web',
    getip_options   => ['web=myip.dnsomatic.com'],
    pid_file        => '/var/run/ddclient.pid',
    enable_ssl      => 'yes',
  }

  ddclient::host { 'namecheap':
    login    => 'theclarkhome.com',
    server   => 'dynamicdns.park-your-domain.com',
    protocol => 'namecheap',
    password => lookup('secrets::namecheap'),
    hostname => join($servers, ',')
  }
#  ddclient::host { 'opendns':
#    login    => 'mergwyn',
#    password => lookup('secrets::opendns'),
#    protocol => 'dyndns2',
#    server   => 'updates.opendns.com',
#    hostname => 'Home',
#  }

}
