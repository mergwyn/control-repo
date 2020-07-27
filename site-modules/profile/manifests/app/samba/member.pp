#

class profile::app::samba::member {
  class { '::samba::classic':
    # Mandatory parameters
    domain              => lookup('defaults::workgroup'),
    realm               => lookup('defaults::realm'),
    smbname             => $::facts['networking']['hostname'],
    sambaloglevel       => 1,
    logtosyslog         => false,
    strictrealm         => false,         # * Check for Strict Realm (default: true)
    security            => 'ADS',         # * security mode.
    krbconf             => true,         # * Deploy krb5.conf fil e (default: true)
    nsswitch            => false,         # * Add winbind to nsswitch,
    adminuser           => lookup('defaults::adminuser'),
    adminpassword       => lookup('secrets::domain'),
    globaloptions       => {
      'kerberos method'                           => 'secrets and keytab',
      'ntlm auth'                                 => 'yes',
      'ea support'                                => 'yes',
      # Apple support related
      'vfs objects'                               => 'fruit streams_xattr',
      'fruit:time machine'                        => 'yes',
      'fruit:model'                               => 'MacSamba',
      'fruit:metadata'                            => 'stream',
      'fruit:posix_rename'                        => 'yes',
      'fruit:veto_appledouble'                    => 'no',
      'fruit:wipe_intentionally_left_blank_rfork' => 'yes',
      'fruit:delete_empty_adfiles'                => 'yes',
      # disable printing
      'load printers'                             => 'no',
      'printing'                                  => 'bsd',
      'printcap name'                             => '/dev/null',
      'disable spoolss'                           => 'yes',
      # tuning
      'min receivefile size'                      => '16384',
      'use sendfile'                              => true,
      'aio read size'                             => '16384',
      'aio write size'                            => '16384',
      'max xmit'                                  => '65536',
      # include local configs
      'include'                                   => '/etc/samba/conf.d/shares.conf',
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
    domain      => lookup('defaults::workgroup'),  # * name of the Domain or '*'
    idrangemin  => 500,
    idrangemax  => 19999,
    backend     => 'ad',
    schema_mode => 'rfc2307',
    #unix_nss_info => yes,
  }
}
# vim: sw=2:ai:nu expandtab
