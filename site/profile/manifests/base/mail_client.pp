# postfix for mail

class profile::base::mail_client (
  $password_credentials = undef,
  $password_hash        = '/etc/postfix/sasl-passwords',
  $relayhost            = undef,
  $root_mail_recipient  = undef,
  ) {

  class { 'postfix':
    myorigin            => $::domain,
    relayhost           => $relayhost,
    mydestination       => "\$myhostname, ${::fqdn}, localhost.${::domain}, localhost",
    root_mail_recipient => $root_mail_recipient,
    manage_root_alias   => true,
    mta                 => true,
  }

  postfix::hash { $password_hash:
    ensure  => 'present',
    content => "${relayhost}    ${password_credentials}\n"
  }
  package { 'libsasl2-modules': ensure => present, }
  postfix::config {
    'smtp_sasl_password_maps':          value => "hash:${password_hash}";
    'smtp_sasl_auth_enable':            value => 'yes';
    'smtp_sasl_security_options':       value =>'noanonymous';
    'smtp_tls_security_level':          value => 'encrypt';
    'smtp_tls_wrappermode':             value => 'yes';
  }
}
#
# vim: sw=2:ai:nu expandtab
