# @summary wrapper for samba manifests

class profile::app::samba {

  $type = lookup( { 'name' => 'samba::dc::role', 'default_value' => 'member' } )

  case $type {
    'member': { contain profile::app::samba::member }
    default:  { contain profile::app::samba::dc }
  }

}
