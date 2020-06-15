#
# TODO: remove, not used?

class profile::platform::baseline::darwin::managedmac {

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
