#

class profile::base::ssh_server {
  class { 'ssh::server':
    options              => {
      'HostKey'                         => [
        '/etc/ssh/ssh_host_rsa_key',
        '/etc/ssh/ssh_host_dsa_key',
        '/etc/ssh/ssh_host_ecdsa_key'
      ],
      'ChallengeResponseAuthentication' => 'no',
      'GSSAPIAuthentication'            => 'yes',
      'GSSAPICleanupCredentials'        => 'yes',
      'GSSAPIKeyExchange'               => 'yes',
      'HostbasedAuthentication'         => 'no',
      'IgnoreRhosts'                    => 'yes',
      'KerberosAuthentication'          => 'yes',
      'KeyRegenerationInterval'         => '3600',
      'LoginGraceTime'                  => '120',
      'LogLevel'                        => 'INFO',
      'PermitEmptyPasswords'            => 'no',
      'PermitRootLogin'                 => 'yes',
      'PermitUserEnvironment'           => 'yes',
      'PrintLastLog'                    => 'yes',
      'PrintMotd'                       => 'no',
      'PubkeyAuthentication'            => 'yes',
      'RhostsRSAAuthentication'         => 'no',
      'RSAAuthentication'               => 'yes',
      'ServerKeyBits'                   => '1024',
      'StrictModes'                     => 'yes',
      'SyslogFacility'                  => 'AUTH',
      'TCPKeepAlive'                    => 'yes',
      'UseDNS'                          => 'no',
      'UsePAM'                          => 'yes',
      'UsePrivilegeSeparation'          => 'yes',
      'X11DisplayOffset'                => '10',
      'X11Forwarding'                   => 'yes',
    },
  }
  exec { 'client_keys':
    command => '/usr/bin/ssh-keygen -q -N "" -f /root/.ssh/id_rsa -t rsa',
    creates => '/root/.ssh/id_rsa',
  }
}
# vim: nu sw=2 ai expandtab
