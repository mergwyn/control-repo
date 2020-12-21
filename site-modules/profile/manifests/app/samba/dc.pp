# 
# TODO: complete dev and test

class profile::app::samba::dc {

  # TODO add unison replcaition script and cron entry
  include profile::app::unison

  # support for samba backup as part of backuppc run
  $scripts='/etc/backuppc-scripts/'
  $preuser="${scripts}DumpPreUser/"
  $postuser="${scripts}DumpPostUser/"

  $oldfiles = [
    '/var/lib/samba/sysvol/theclarkhome.com/scripts/samba4_backup',
    '/etc/cron.daily/samba4-backup',
    '/etc/backuppc/scripts/DumpPreUser/S30samba_backup',
    '/etc/backuppc/scripts/DumpPostUser//P30samba_clean'
  ]
  file {$oldfiles: ensure => absent, }

  file { "${preuser}/S30samba_backup":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S30samba_backup',
    mode   => '0555',
  }
  file { "${postuser}/P30samba_clean":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/P30samba_clean',
    mode   => '0555',
  }
  #class { '::samba::dc':
    #domain             => $trusted['domain'],
    #realm              => lookup("default::realm"),
    #adminpassword      => lookup("secrets::adminpassword"),
    #dnsbackend         => 'internal',
    #dnsforwarder       => '8.8.8.8',
    #domainlevel        => '2008 R2',
    #domainprovargs     => '--use-xattrs=yes --use-ntvfs',
    #sambaloglevel      => 1,
    #logtosyslog        => true,
    #sambaclassloglevel => {
    #  'dns'   => 2,
    #  'idmap' => 2,
    #  'auth'  => 3,
    #},
# TODO check that these are all needed
    #globaloptions       => {
      #'client use spnego' => 'no',
      #'kerberos method'   => 'secrets and keytab',
      #'lm announce'       => 'no',
      #'ntlm auth'         => 'no',
      #'client ntlmv2 auth' => 'yes',
      #'server services'   => 's3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, winbindd, ntp_signd, kcc, dnsupdate, dns'
    #},
# TODO check if options are needed here
    #netlogonoptions       => {},
    #sysvoloptions         => {},

  #}

# TODO migrate rest of setup script
  #class { '::samba::dc::ppolicy':
  #  ppolicycomplexity    => 'on',
  #  ppolicyplaintext     => 'off',
  #  ppolicyhistorylength => 12,
  #  ppolicyminpwdlength  => 10,
  #  ppolicyminpwdage     => 1,
  #  ppolicymaxpwdage     => 90,
  #}

  #smb_user { 'administrator':
  #  ensure     => present,
  #  password   => 'c0mPL3xe_P455woRd',
  #  attributes => {
  #    uidNumber        => '15220',
  #    gidNumber        => '15220',
  #    msSFU30NisDomain => 'dc',
  #    scriptPath       => 'login1.cmd',
  #  },
  #  groups     => ['domain users', 'administrators'],
  #}

  #smb_group { 'mygroup':
  #  ensure     => present,
  #  scope      => 'Domain',
  #  type       => 'Security',
  #  attributes => {
  #    gidNumber        => '15222',
  #    msSFU30NisDomain => 'dc',
  #  },
  #  groups     => ['domain users', 'administrators'],
  #}

}
