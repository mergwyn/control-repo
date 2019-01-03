#

class profile::base::linux {
  # core stuff
  $packages_present = [
    'ubuntu-standard',
    'update-notifier-common',
    'landscape-common',
    'vim',
    'anacron',
    'gpg',
  ]
  package { $packages_present: ensure => present, }
  $packages_absent = [
    'vim-tiny',
    'mlocate'
  ]
  package { $packages_absent:   ensure => absent, }

  file { '/etc/legal':                  ensure  => absent, }
  file { '/etc/vim/vim.local':          ensure  => absent, }
  file { '/etc/vim/vimrc.local':
    ensure => present,
    source => 'puppet:///modules/profile/vimrc.local',
  }
  file { '/etc/update-motd.d/10-help-text': ensure  => absent, }
  file { '/etc/landscape/client.conf':
    ensure  => present,
    content => "[sysinfo]\nexclude_sysinfo_plugins = LandscapeLink\n",
  }

  if $::is_virtual == false or str2bool($::is_virtual) == false {
    file { '/etc/udev/rules.d/11-media-by-label-auto-mount.rules':
      ensure => present,
      source => 'puppet:///modules/profile/11-media-by-label-auto-mount.rules',
    }
  }
  host { $facts['networking']['hostname']:
    ensure => absent,
    ip     => '127.0.1.1',
  }
  host { $facts['networking']['fqdn']:
    ensure       => present,
    host_aliases => $facts['networking']['hostname'],
    ip           => '127.0.1.1',
  }
  host { 'localhost':
    ensure => absent,
    ip     => '127.0.0.1',
  }
  host { $facts['networking']['hostname']:
    ensure       => present,
    host_aliases => "$facts['networking']['hostname'] localhost",
    ip           => '127.0.0.1',
  }

  include profile::base::core_users
  include profile::base::avahi
  include profile::base::ssh_server
  include profile::base::mail_client
  include profile::base::unattended_upgrades
  include profile::base::webmin_generic
  include profile::zabbix::agent
  include profile::backuppc::client
}


# vim: sw=2:ai:nu expandtab
