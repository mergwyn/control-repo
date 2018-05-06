#

class profile::domain_sso {
  exec { 'create_keytab':
    command => '/usr/bin/net ads keytab create -P',
    creates => '/etc/krb5.keytab',
    require => [
      Package[ 'samba-common-bin'],
    ]
  }
  package { 'samba-common-bin': }
  class { '::sssd':
    config => {
      'sssd'                    => {
        'services'            => ['nss', 'pam', 'sudo'],
        'config_file_version' => 2,
        'domains'             => $::domain,
      },
      'nss'                     => {
        'filter_groups' => 'root',
        'filter_users'  => 'root'
      },
      'sudo'                    => {
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
      }
    }
  }


  # work around for cron starting before sssd
  $crondir = '/etc/systemd/system/cron.service.d'
  if $::facts['os']['release']['full'] == '16.04' {
    file { $crondir: ensure => directory }
    file { "${crondir}/override.conf":
      ensure  => present,
      content => '[Service]\nRequires=nss-lookup.target\n',
    }
  } else {
    file { "${crondir}/override.conf": ensure => absent }
    file { $crondir: ensure => absent }
  }
}
# vim: sw=2:ai:nu expandtab
