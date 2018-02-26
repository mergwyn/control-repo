#

class profile::samba_member {
  class { '::samba::classic':
    # Mandatory parameters
    domain                => hiera("defaults::workgroup"),
    realm                 => hiera("defaults::realm"),
    smbname               => $hostname,     # * Share name
    sambaloglevel         => 2,
    #logtosyslog           => true,

    strictrealm           => false,         # * Check for Strict Realm (default: true)
    security              => 'ADS',         # * security mode.
    krbconf               => false,         # * Deploy krb5.conf fil e (default: true)
    nsswitch              => false,         # * Add winbind to nsswitch,
    adminuser             => hiera("defaults::adminuser"),
    adminpassword         => hiera("passwords::domain"),
    globaloptions => {
      'kerberos method' => 'secrets and keytab',
      'include'       => '/etc/samba/conf.d/tuning.conf',
      'include'       => '/etc/samba/conf.d/mapping.conf',
      'include'       => '/etc/samba/conf.d/printer.conf',
      'include'       => '/etc/samba/conf.d/shares.conf',
    },                # * Custom options in section [global]
    globalabsentoptions => [],              # * Remove default settings put
  }
  ::samba::idmap { 'Domain *':
    domain      => '*',           # * name of the Domain or '*'
    idrangemin  => 70001,         # * Min uid for Domain users
    idrangemax  => 80000,         # * Max uid for Domain users
    backend     => 'tdb',         # * idmap backend
  }
  ::samba::idmap { 'Domain DC':
    domain      => hiera("defaults::workgroup"),  # * name of the Domain or '*'
    idrangemin  => 500,
    idrangemax  => 19999,
    backend     => 'ad',
    schema_mode => 'rfc2307',
  }
}
# vim: sw=2:ai:nu expandtab
