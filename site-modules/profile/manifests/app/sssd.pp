#
#
class profile::app::sssd {

  require profile::app::samba

  $keytab = '/etc/krb5.keytab'
#  exec { 'create_keytab':
#    command => '/usr/bin/net ads keytab create -P',
#    creates => $keytab,
#  }
  class { '::sssd':
    config  => {
      'sssd'                    => {
#        'services'            => ['nss', 'pam'],
        'config_file_version' => 2,
        'domains'             => $trusted['domain'],
      },
      'nss'                     => {
        'filter_groups' => 'root',
        'filter_users'  => 'root'
      },
      'domain/theclarkhome.com' => {
        'access_provider'                => 'ad',
        'ad_domain'                      => $trusted['domain'],
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
# TODO workaorund https://bugs.launchpad.net/ubuntu/+source/sssd/+bug/1934997
        'ad_gpo_access_control'          => 'permissive',
      },
    },
    #require => Service[ 'SambaWinBind' ],
  }

  # remove sudo sss setting
  augeas { 'nsswitch.conf':
    context => '/files/etc/nsswitch.conf',
    changes => [
      "set *[self::database = 'sudoers']/service[1] files",
      "rm *[self::database = 'sudoers']/service[2] ",
    ],
  }

  include profile::platform::baseline::debian::apparmor
  file { '/etc/apparmor.d/local/usr.sbin.sssd':
    ensure  => file,
    notify  => Service['sssd', 'apparmor'],
    owner   => 'root',
    group   => 'root',
    content => @("EOT"),
               /etc/group r,
               /etc/hosts r,
               /etc/krb5.conf r,
               /etc/sssd/conf.d/ r,
               /proc/*/cmdline r,
               /usr/libexec/sssd/* ix,
               /var/lib/samba/private/krb5.conf r,
               /var/lib/sss/pubconf/** rw,
               | EOT
  }

  # work around for cron starting before sssd
  $crondir = '/etc/systemd/system/cron.service.d'
  include cron
  ::systemd::dropin_file { 'sssd-wait.conf':
    unit    => 'cron.service',
    content => "[Unit]\nAfter=nss-user-lookup.target\n",
    notify  => Service['cron'],
  } #~> service {'cron': ensure    => 'running', }

  # work aorund for bug where ssd pid file is not handled
  ::systemd::dropin_file { 'sssd-pidfile.conf':
    unit    => 'sssd.service',
    content => "[Service]\nPIDFile=/run/sssd.pid\n",
    notify  => Service['sssd'],
  }
}
