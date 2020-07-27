# @summary wrapper for samba manifests

class profile::app::samba {

  $type = lookup( { 'name' => 'samba::dc::role', 'default_value' => 'member' } )

  case $type {
    'member': { include profile::app::samba::member }
    default:  { include profile::app::samba::dc }
  }

}
