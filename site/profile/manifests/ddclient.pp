#

class profile::ddclient {

  class { 'ddclient': 
    hosts_config     => 'concat',
    daemon_interval => 300,
    getip_from      => 'web',
    getip_options   => ['web=myip.dnsomatic.com'],
    data_dir        => '/tmp/ddclient.cache',
    pid_file        => '/var/run/ddclient.pid',
    enable_ssl      => 'yes',
  }

  ddclient::host { 'namecheap':
    login    => 'theclarkhome.com',
    server   => 'dynamicdns.park-your-domain.com',
    protocol => 'namecheap',
    password => hiera("passwords::namecheap"),
    #hostname => 'webmin,zulu,tango,papa,foxtrot,echo,vpn',
    hostname => 'vpn',
  }
  ddclient::host { 'opendns':
    login    => 'mergwyn',
    password => hiera("passwords::opendns"),
    protocol => 'dyndns2',
    server   => 'updates.opendns.com',
    hostname => 'Home',
  }

}
# vim: sw=2:ai:nu expandtab
