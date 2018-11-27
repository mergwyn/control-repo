#

class profile::base {
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
    ensure       => absent,
    ip           => '127.0.1.1',
  }
  host { $facts['networking']['fqdn']:
    ensure       => present,
    host_aliases => $facts['networking']['hostname'],
    ip           => '127.0.1.1',
  }

  include profile::core_users
  include profile::avahi
  include profile::ssh_server
  include profile::mail_client
  include profile::unattended_upgrades
  include profile::webmin_generic
  include profile::zabbix::agent
  include profile::backuppc::client
}


# vim: sw=2:ai:nu expandtab
