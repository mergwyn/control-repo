# @summary ssh client and server config
#
# @param collect_keys
#   Set storeconfigs_enabled to collect and distribute keys
#
class profile::platform::baseline::debian::ssh (
  Boolean $collect_keys = true,
) {

# The values below have been set for an Ubuntu 20.04 distribution
# Values may need to be changed for different versions
  class { 'ssh':
    storeconfigs_enabled => $collect_keys,
    client_options       => {
      'PasswordAuthentication'    => 'yes',
      'PubkeyAuthentication'      => 'yes',
      'HostbasedAuthentication'   => 'yes',
      'IdentityFile'              => [ '~/.ssh/id_rsa', '~/.ssh/id_dsa' ],
      'Protocol'                  => '2',
      'HashKnownHosts'            => 'yes',
      'GlobalKnownHostsFile'      => '/etc/ssh/ssh_known_hosts',
      'GSSAPIAuthentication'      => 'yes',
      'GSSAPIDelegateCredentials' => 'yes',
      'ForwardX11Trusted'         => 'yes',
      'UseRoaming'                => 'no',
      'SendEnv'                   => [
        'LANG LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES',
        'LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT',
        'LC_IDENTIFICATION LC_ALL',
      ],
      'EnableSSHKeysign'          => 'yes',
      'Host cisco1'               => {
        'HostkeyAlgorithms' => 'ssh-dss,ssh-rsa',
        'KexAlgorithms'     => '+diffie-hellman-group1-sha1,diffie-hellman-group14-sha1',
      }

    },
    server_options       => {
      'LoginGraceTime'                  => '120',
      'PermitRootLogin'                 => 'without-password',
      'HostbasedAuthentication'         => 'yes',
      'IgnoreUserKnownHosts'            => 'no',
      'IgnoreRhosts'                    => 'yes',
      'PasswordAuthentication'          => 'yes',
      'PermitEmptyPasswords'            => 'no',
      'ChallengeResponseAuthentication' => 'yes',
      'KerberosAuthentication'          => 'yes',
      'GSSAPIAuthentication'            => 'yes',
      'GSSAPICleanupCredentials'        => 'yes',
      'UsePAM'                          => 'yes',
      'AcceptEnv'                       => [
        'LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES',
        'LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT',
        'LC_IDENTIFICATION LC_ALL',
      ],
      'AllowTcpForwarding'              => 'yes',
      'X11Forwarding'                   => 'yes',
      'X11UseLocalhost'                 => 'yes',
      'PrintMotd'                       => 'yes',
      'PrintLastLog'                    => 'yes',
      'PermitUserEnvironment'           => 'yes',
      'ClientAliveInterval'             => '0',
      'ClientAliveCountMax'             => '3',
      'UseDNS'                          => 'yes',
      'Banner'                          => 'none',
      'Subsystem'                       => 'sftp /usr/lib/openssh/sftp-server',
    },
  }

}
