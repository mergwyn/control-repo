# 
# TODO: delete, not used

class profile::static_network {
  class { 'network':
    interfaces_hash => {
      'eth0' => {
	ipaddress       => '192.168.11.13',
	netmask         => '255.255.255.0',
	network         => '192.168.11.0',
        gateway         => '192.168.11.254',
        dns_nameservers => '192.168.11.11 192.168.11.10',
        dns_search      => 'theclarkhome.com local',
    }
  }
}
# vim: sw=2:ai:nu expandtab
