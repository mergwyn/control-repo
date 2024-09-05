#
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
      'vfs objects'                               => 'acl_xattr fruit streams_xattr aio_pthread',
      'acl_xattr:ignore system acls'              => 'yes',
      # Fruit settings
      'fruit:aapl'                                => 'yes',
      'fruit:model'                               => 'MacSamba',
      'fruit:metadata'                            => 'stream',
      'fruit:posix_rename'                        => 'yes',
      'fruit:veto_appledouble'                    => 'no',
      'fruit:wipe_intentionally_left_blank_rfork' => 'yes',
      'fruit:delete_empty_adfiles'                => 'yes',
      'fruit:nfs_aces'                            => 'no',
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
      'recycle:keeptree'                          => 'no',
      'oplocks'                                   => 'yes',
      'locking'                                   => 'yes',
      'max xmit'                                  => '65536',
      # Other settings
      'map acl inherit'                           => 'Yes',
      'store dos attributes'                      => 'Yes',
      'inherit acls'                              => 'true',
      'admin users'                               => '"admin","THECLARKHOME\administrator","THECLARKHOME\gary"',
      'kernel oplocks'                            => 'no',
      'unix extensions'                           => 'no',
      'veto oplock files'                         => @(EOT/L),
                                                     /*.mdb/\
                                                     *.MDB/\
                                                     *.idx/\
                                                     *.dbf/\
                                                     *.cdx/\
                                                     *.fpt/\
                                                     *.IDX/\
                                                     *.DBF/\
                                                     *.CDX/\
                                                     *.FPT/
                                                     |- EOT
      'veto files'                                => @(EOT/L),
                                                     /.zfs/\
                                                     $RECYCLE.BIN/\
                                                     Network Trash Folder/\
                                                     Temporary Items/\
                                                     .AppleDouble/\
                                                     .AppleDesktop/\
                                                     Network Trash Folder/\
                                                     TheVolumeSettingsFolder/\
                                                     Icon?/\
                                                     .Trashes/\
                                                     ._.Trashes/\
                                                     :2eDS_Store/\
                                                     .DS_Store/\
                                                     ._*/
                                                     |- EOT

    },
    globalabsentoptions => [
      'map untrusted to domain',              # * Remove default settings put
      'winbind trusted domains only',         # deprecated
      'winbind separator',                    # causes auth error
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
