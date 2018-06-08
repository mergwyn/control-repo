# 
# TODO: complete dev and test

class profile::samba_dc {

  package { 'unison': }
  file { '/etc/cron.daily/samba4-backup':
    content => "#!/bin/sh\n/var/lib/samba/sysvol/theclarkhome.com/scripts/samba4_backup\n",
    mode    => '0755',
  }

  # support for backup as part of backuppc run

  $scripts='/etc/backuppc/scripts/'
  $preuser="${scripts}DumpPreUser/"
  $postuser="${scripts}DumpPostUser/"

  $oldfiles = [ 
    '/var/lib/samba/sysvol/theclarkhome.com/scripts/samba4_backup',
    '/etc/cron.daily/samba4-backup'
  ]
  file {$oldfiles: ensure => absent, }

  file { "${preuser}/S30samba_backup":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S30samba_backup',
    mode   => '0555',
  }
  file { "${preuser}/P30samba_clean":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/P30samba_clean',
    mode   => '0555',
  }
    #class { '::samba::dc':
    #}
    #class { '::samba::dc':
      #role               => 'join',
      #domain             => hiera("workgroup"),
      #realm              => hiera("realm"),
      #dnsbackend         => 'internal',
      #domainlevel        => '2008 R2',
      #sambaloglevel      => 2,
      #logtosyslog        => true,
      #adminpassword      => hiera("adminpassword"),

      #ip                 => '192.168.199.80',
      #sambaclassloglevel => {
      #  'smb'   => 2,
      #  'idmap' => 2,
      #},
      #dnsforwarder       => '192.168.199.42',
    #}

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
# vim: sw=2:ai:nu expandtab
