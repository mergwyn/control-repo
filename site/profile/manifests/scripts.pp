#

class profile::scripts {

  include profile::git

  $codedir='/opt/code/scripts'

  # common scripts
  vcsrepo { $codedir:
      ensure   => present,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/scripts.git',
      revision => 'master',
  }

}
# vim: sw=2:ai:nu expandtab
