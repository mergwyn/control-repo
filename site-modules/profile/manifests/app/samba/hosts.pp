# @summary Add dnsentries

class profile::app::samba::hosts
{
# TODO read from hiera or exported resource?
  profile::app::samba::dnsentry { 'golf':    ipaddress => '192.168.11.11' }
  profile::app::samba::dnsentry { 'foxtrot': ipaddress => '192.168.11.12' }
  profile::app::samba::dnsentry { 'juliet':  ipaddress => '192.168.11.251' }
  profile::app::samba::dnsentry { 'victor':  ipaddress => '192.168.11.252' }
}
