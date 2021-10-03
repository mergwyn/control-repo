# @summary Add dnsentries
#
class profile::app::samba::hosts(
  $subnet =  lookup('defaults::subnet'),
) {
# TODO read from hiera or exported resource?
#  profile::app::samba::dnsentry { 'romeo':   ipaddress => "${subnet}.1" }
#  profile::app::samba::dnsentry { 'golf':    ipaddress => "${subnet}.11" }
#  profile::app::samba::dnsentry { 'foxtrot': ipaddress => "${subnet}.12" }
#  profile::app::samba::dnsentry { 'juliet':  ipaddress => "${subnet}.251" }
#  profile::app::samba::dnsentry { 'victor':  ipaddress => "${subnet}.252" }
}
