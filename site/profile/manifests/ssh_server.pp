#

class profile::ssh_server {
  class { '::ssh':
    sshd_config_hostkey                  => [
      '/etc/ssh/ssh_host_rsa_key',
      '/etc/ssh/ssh_host_dsa_key',
      '/etc/ssh/ssh_host_ecdsa_key'
    ],
    #'KerberosAuthentication'          => 'no',
    #'KeyRegenerationInterval'         => '3600',
    permit_root_login                    => 'yes',
    #'RSAAuthentication'               => 'yes',
    sshd_config_challenge_resp_auth      => 'no',
    sshd_config_login_grace_time         => '120',
    sshd_config_loglevel                 => 'INFO',
    sshd_config_permitemptypasswords     => 'no',
    #sshd_config_print_lastlog            => 'yes',
    sshd_config_print_motd               => 'no',
    sshd_config_serverkeybits            => '1024',
    sshd_config_strictmodes              => 'yes',
    sshd_config_syslog_facility          => 'AUTH',
    sshd_config_tcp_keepalive            => 'yes',
    sshd_config_use_dns                  => 'no',
    sshd_config_use_privilege_separation => 'yes',
    sshd_gssapiauthentication            => 'yes',
    sshd_gssapicleanupcredentials        => 'yes',
    sshd_gssapikeyexchange               => 'yes',
    sshd_hostbasedauthentication         => 'no',
    sshd_ignorerhosts                    => 'yes',
    sshd_pubkeyauthentication            => 'yes',
    sshd_use_pam                         => 'yes',
    sshd_x11_forwarding                   => 'yes',
    #'X11DisplayOffset'                => '10',
  }
  exec { 'client_keys':
    command => '/usr/bin/ssh-keygen -q -N "" -f /root/.ssh/id_rsa -t rsa',
    creates => '/root/.ssh/id_rsa',
  }
}
# vim: sw=2:ai:nu expandtab
