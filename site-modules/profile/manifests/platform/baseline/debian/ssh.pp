# @summary ssh client and server config

class profile::platform::baseline::debian::ssh {

# TODO: check defaults for clean bionic install
  class { 'ssh':
    ssh_hostbasedauthentication       => 'yes',
    ssh_gssapiauthentication          => 'yes',
    ssh_gssapidelegatecredentials     => 'yes',
    ssh_enable_ssh_keysign            => 'yes',

    sshd_gssapiauthentication         => 'yes',
    sshd_gssapicleanupcredentials     => 'yes',
    sshd_kerberos_authentication      => 'yes',
    sshd_hostbasedauthentication      => 'yes',
    sshd_config_permitemptypasswords  => 'no',
    sshd_config_print_last_log        => 'yes',
    sshd_config_permituserenvironment => 'yes',
  }
}
