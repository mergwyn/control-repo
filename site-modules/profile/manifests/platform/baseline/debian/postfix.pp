# @summary postfix for mail
#
class profile::platform::baseline::debian::postfix {

  $password_credentials = "mergwyn@virginmedia.com:${lookup('secrets::virgin')}"
  $relayhost            = '[smtp.virginmedia.com]:465'
  $password_hash        = '/etc/postfix/sasl-passwords'

  class { 'postfix':
    myorigin            => $trusted['domain'],
    relayhost           => $relayhost,
    mydestination       => "\$myhostname, ${trusted['certname']}, localhost.${trusted['domain']}, localhost",
    mynetworks          => '192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.0/8 [fd00::/8] [::ffff:127.0.0.0]/104 [::1]/128',
    root_mail_recipient => lookup('defaults::adminemail'),
    manage_root_alias   => true,
    mta                 => true,
  }

  #postfix::mailalias { 'media': recipient => lookup('defaults::adminemail'), ensure => present, }

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
