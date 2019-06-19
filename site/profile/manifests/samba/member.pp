#

class profile::samba::member {
  class { '::samba::classic':
    # Mandatory parameters
    domain              => hiera('defaults::workgroup'),
    realm               => hiera('defaults::realm'),
    smbname             => $::facts['networking']['hostname'],
    sambaloglevel       => 2,
    logtosyslog         => false,
    sambaclassloglevel  => {
      'auth'    => 3,
      'idmap'   => 5,
      'winbind' => 3,
    },
    strictrealm         => false,         # * Check for Strict Realm (default: true)
    security            => 'ADS',         # * security mode.
    krbconf             => true,         # * Deploy krb5.conf fil e (default: true)
    nsswitch            => false,         # * Add winbind to nsswitch,
    adminuser           => hiera('defaults::adminuser'),
    adminpassword       => hiera('secrets::domain'),
    globaloptions       => {
      'kerberos method'      => 'secrets and keytab',
      'ntlm auth'            => 'yes',
      # disable printing
      'load printers'        => 'no',
      'printing'             => 'bsd',
      'printcap name'        => '/dev/null',
      'disable spoolss'      => 'yes',
      # tuning
      'min receivefile size' => '16384',
      'use sendfile'         => true,
      'aio read size'        => '16384',
      'aio write size'       => '16384',
      'max xmit'             => '65536',
      # include local configs
      'include'              => '/etc/samba/conf.d/shares.conf',
    },                # * Custom options in section [global]
    globalabsentoptions => [
      'map untrusted to domain',              # * Remove default settings put
    ]
  }
  ::samba::idmap { 'Domain *':
    domain     => '*',           # * name of the Domain or '*'
    idrangemin => 70001,         # * Min uid for Domain users
    idrangemax => 80000,         # * Max uid for Domain users
    backend    => 'tdb',         # * idmap backend
  }
  ::samba::idmap { 'Domain DC':
    domain      => hiera('defaults::workgroup'),  # * name of the Domain or '*'
    idrangemin  => 500,
    idrangemax  => 19999,
    backend     => 'ad',
    schema_mode => 'rfc2307',
    #unix_nss_info => yes,
  }
}
# vim: sw=2:ai:nu expandtab
