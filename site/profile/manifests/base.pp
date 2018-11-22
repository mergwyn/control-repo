#

class profile::base {
  # core stuff
  package { 'ubuntu-standard':          ensure => present, }
  package { 'update-notifier-common':   ensure => present, }
  package { 'landscape-common':         ensure => present, }
  package { 'vim':                      ensure => present, }
  package { 'anacron':                  ensure => present, }
  package { [ 'vim-tiny', 'mlocate' ]:  ensure => absent, }

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
  host { $::facts['hostname']:
    ensure       => absent,
    ip           => '127.0.1.1',
  }
  host { $::facts['fqdn']:
    ensure       => present,
    host_aliases => $::facts['hostname'],
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
