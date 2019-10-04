#
# TODO: remove, not used?

class profile::mac::managedmac {
  package { 'jdbc-sqlite3':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'CFPropertyList':
    ensure   => 'installed',
    provider => 'gem',
  }
  include managedmac
}
# vim: sw=2:ai:nu expandtab
