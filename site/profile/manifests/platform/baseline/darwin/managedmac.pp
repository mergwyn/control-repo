#
# TODO: remove, not used?

class profile::platform::baseline::darwin::managedmac {

  package { 'jdbc-sqlite3':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'CFPropertyList':
    ensure   => 'installed',
    provider => 'gem',
  }


# TODO: refactor mamagedmac to remove hiera mandate
#  class { 'managedmac':
#    # organization => 'The Clark family',
#  }

# TODO: use common set of timeservers
  class { 'managedmac::ntp':
    enable  => true,
    servers => [
      "bravo.${trusted['domain']}",
      "alpha.${trusted['domain']}",
      'time.euro.apple.com',
      'time.apple.com',
    ],
  }

  class { 'managedmac::loginwindow':
    loginwindow_text              => "This is ${trusted['hostname']}",
    show_name_and_password_fields => true,
    enable_fast_user_switching    => true,
    hide_admin_users              => false,
  }

  class { 'managedmac::activedirectory':
    enable                         => true,
    # evaluate => "%{::domain_available?}",
    evaluate                       => 'yes',
    provider                       => dsconfigad,
    hostname                       => $trusted['domain'],
    username                       => 'administrator',
    password                       => lookup('secrets::domain'),
    computer                       => $trusted['hostname'],
    mount_style                    => smb,
    create_mobile_account_at_login => true,
    force_home_local               => true,
    warn_user_before_creating_ma   => true,
    use_windows_unc_path           => true,
    default_user_shell             => '/bin/bash',
    map_uid_attribute              => 'uidNumber',
    map_gid_attribute              => 'gidNumber',
    map_ggid_attribute             => 'gidNumber',
    domain_admin_group_list        => [
      'THECLARKHOME\Administrators',
      'THECLARKHOME\Domain Admins',
      'THECLARKHOME\Enterprise Admins',
    ],
  }

  #class { 'managedmac::loginhook':  enable => true, }
  #class { 'managedmac::logouthook': enable => true, }

  class { 'managedmac::security':
    ask_for_password       => true,
    ask_for_password_delay => 0,
  }

  class { 'managedmac::screensharing': enable => true, }

  class { 'managedmac::sshd':
    enable      => true,
#   sshd_config => 'puppet:///modules/your_module/sshd_config',
  }

}
