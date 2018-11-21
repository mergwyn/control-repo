#

class profile::domain::sso {
  $type = lookup( { "name" => "samba::dc::role", "default_value" => "member" } )

  case $type {
    'member': { $require = 'profile::domain::member' }
    default:  { $require = 'profile::domain::dc' }
  }
  #notify {"samba:dc:role $type for $::fqdn requires $require":}

  exec { 'create_keytab':
    command => '/usr/bin/net ads keytab create -P',
    creates => '/etc/krb5.keytab',
    require => [ Class[ $require ] ],
  }
  class { '::sssd':
    config => {
      'sssd'                    => {
        'services'            => ['nss', 'pam'],
        'config_file_version' => 2,
        'domains'             => $::domain,
      },
      'nss'                     => {
        'filter_groups' => 'root',
        'filter_users'  => 'root'
      },
      'domain/theclarkhome.com' => {
        'accessprovider'                 => 'ad',
        'ad_domain'                      => $::domain,
        'auth_provider'                  => 'ad',
        'cache_credentials'              => true,
        'debug_level'                    => '1',
        'dyndns_update'                  => false,
        'enumerate'                      => true,
        'id_provider'                    => 'ad',
        'krb5_keytab'                    => '/etc/krb5.keytab',
        'krb5_store_password_if_offline' => true,
        'ldap_id_mapping'                => false,
        'ldap_sasl_mech'                 => 'gssapi',
        'ldap_uri'                       => ['ldap://bravo.theclarkhome.com,ldap://alpha.theclarkhome.com'],
        'ldap_use_tokengroups'           => false,
        'use_fully_qualified_names'      => false,
      },
      require => Exec[ 'create_keytab' ],
    }
  }

  # remove sudo sss setting
  augeas { 'nsswitch.conf':
    context => "/files/etc/nsswitch.conf",
    changes => [
      "set *[self::database = 'sudoers']/service[1] files",
      "rm *[self::database = 'sudoers']/service[2] ",
    ],
  }

  include profile::apparmor
  file { "/etc/apparmor.d/local/usr.sbin.sssd":
    ensure  => file,
    notify  => Service['sssd', 'apparmor'],
    content  => "  /var/lib/samba/private/krb5.conf r,\n",
    owner   => 'root',
    group   => 'root',
  }

  # work around for cron starting before sssd
  $crondir = '/etc/systemd/system/cron.service.d'
  if $::facts['os']['release']['full'] == '16.04' or
     $::facts['os']['release']['full'] == '18.04'  {
    include cron
    ::systemd::dropin_file { 'sssd-wait.conf':
      unit    => 'cron.service',
      content => "[Unit]\nAfter=nss-user-lookup.target\n",
      notify  => Service['cron'],
    } #~> service {'cron': ensure    => 'running', }
    file { "${crondir}/ssdwait.conf": ensure => absent }
  } else {
    file { "${crondir}/sssd-wait.conf": ensure => absent }
    file { $crondir: ensure => absent }
  }
  # work aorund for bug where ssd pid file is not handled
  ::systemd::dropin_file { 'sssd-pidfile.conf':
    unit    => 'sssd.service',
    content => "[Service]\nPIDFile=/var/run/sssd.pid\n",
    notify  => Service['sssd'],
  }
}
# vim: sw=2:ai:nu expandtab
