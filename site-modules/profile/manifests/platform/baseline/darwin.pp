#
#
class profile::platform::baseline::darwin {
  include profile::platform::baseline::users::darwin
  include profile::platform::baseline::darwin::brew
  include profile::platform::baseline::darwin::timemachine
  include profile::platform::baseline::darwin::packages

  File {
    owner => 'root',
    group => 'admin',
    ensure => file,
  }

  file { '/etc/krb5.config':
    source => 'puppet:///modules/profile/mac/krb5.conf',
    group  => 'wheel',
  }
  file { '/etc/ssh/sshd_config.d/200-gssapi.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    content => @(EOT),
      # Managed by Puppet
      # Add gssapi options to allow kerberos auth to work with sshd
      GSSAPIAuthentication yes
      GSSAPICleanupCredentials yes
      | EOT
    notify  => Service['com.openssh.sshd'],
  }

  file { '/etc/ssh/ssh_config.d/200-gssapi.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    content => @("EOT"),
      # Managed by Puppet
      # Add gssapi options to allow kerberos auth to work with ssh
      Host *.$trusted['domain']
          # SendEnv LANG LC_*
        ForwardX11 yes
        GSSAPIAuthentication yes
        GSSAPIDelegateCredentials yes
      | EOT
    notify  => Service['com.openssh.sshd'],
  }

  service { 'com.openssh.sshd':
    ensure     => running,
    enable     => true,
    provider   => 'launchd',
    hasrestart => true,
    restart    => '/bin/launchctl kickstart -k system/com.openssh.sshd',
  }
}
