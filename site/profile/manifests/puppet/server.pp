#

class profile::puppet::server {

  #include '::puppet'
  #include '::puppet::master'

  include profile::puppet::repo

  class { 'r10k':
    cachedir => '/var/cache/r10k',
    sources  => {
      'mergwyn' => {
        'remote'  => 'https://github.com/mergwyn/control-repo',
        'basedir' => "${::settings::codedir}/environments",
      },
    },
  }

  # Configure puppetdb and its underlying database
  $puppetdb_host = $::facts['networking']['fqdn']
  $postgres_host = $::facts['networking']['fqdn']

  class { 'puppetdb::database::postgresql': 
    listen_addresses => $postgres_host,
  }
  class { 'puppetdb':
    database_host  => $puppetdb_host,
    listen_address => '0.0.0.0',
  }
  # Configure the Puppet master to use puppetdb
  class { 'puppetdb::master::config':
    puppetdb_server => $puppetdb_host,
  }

  # Clean old reports
  include cron
  cron::job { 'puppet_reports':
    command => '/usr/bin/find /opt/puppetlabs/server/data/puppetserver/reports -type f -name "*.yaml" -mtime +30 -exec /bin/rm {} ";"',
    user    => 'root',
    minute  => 4,
    hour    => 2,
  }

  # Configure Apache on this server
  class { 'apache': }
  class { 'apache::mod::wsgi': }
  
  # Configure Puppetboard
  class { 'puppetboard':
    manage_git          => true,
    manage_virtualenv   => true,
    default_environment => '*',
  }
  # Access Puppetboard through pboard.example.com
  class { 'puppetboard::apache::vhost':
    vhost_name => 'echo.theclarkhome.com',
    port       => 80,
  }

  $scripts=hiera('profile::backuppc::scripts')
  $preuser=hiera('profile::backuppc::preuser')
  $postuser=hiera('profile::backuppc::postuser')

  file { "${preuser}/S21postgresql-backup":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/S20postgresql-backup',
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

  file { "${postuser}/P21postgresql-backup-clean":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/P21postgresql-backup-clean',
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

}
