#
#
class profile::puppet::server {

  #include '::puppet'
  #include '::puppet::master'

  include profile::puppet::repo

  class { 'r10k':
    cachedir => '/var/cache/r10k',
    sources  => {
      'mergwyn' => {
        'remote'           => 'https://github.com/mergwyn/control-repo',
        'environment_name' => "${::settings::codedir}/environments",
      },
    },
  }

  # Configure puppetdb and its underlying database
  include puppetdb
  include puppetdb::master::config

  # Clean old reports
  include cron
  cron::job { 'puppet_reports':
    command => '/usr/bin/find /opt/puppetlabs/server/data/puppetserver/reports -type f -name "*.yaml" -mtime +30 -exec /bin/rm {} ";"',
    user    => 'root',
    minute  => 4,
    hour    => 2,
  }

  # Configure Apache on this server
#  class { 'apache': }
#  class { 'apache::mod::wsgi':
#    package_name           => 'libapache2-mod-wsgi-py3',
#    mod_path               => '/usr/lib/apache2/modules/mod_wsgi.so',
#    wsgi_application_group => 'puppet',
#  }

  # Configure Puppetboard
  class { 'puppetboard':
    manage_git          => true,
    manage_virtualenv   => true,
    default_environment => 'production',
    secret_key          => fqdn_rand_string(32),
  }
  # Access Puppetboard through pboard.example.com
  class { 'puppetboard::apache::vhost':
    vhost_name => 'echo.theclarkhome.com',
    port       => 80,
  }

  $scripts  = hiera('profile::app::backuppc::client::scripts')
  $preuser  = hiera('profile::app::backuppc::client::preuser')
  $postuser = hiera('profile::app::backuppc::client::postuser')

  file { "${preuser}/S21postgresql-backup":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/S21postgresql-backup',
    mode    => '0555',
    require => Class['profile::app::backuppc::client'],
  }

  file { "${postuser}/P21postgresql-backup-clean":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/P21postgresql-backup-clean',
    mode    => '0555',
    require => Class['profile::app::backuppc::client'],
  }

}
