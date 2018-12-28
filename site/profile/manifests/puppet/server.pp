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
  class { 'puppetdb': }
  # Configure the Puppet master to use puppetdb
  class { 'puppetdb::master::config': }
  # Clean old reports
  tidy { '/opt/puppetlabs/server/data/puppetserver/reports':
    age     => '30d',
    matches => '*.yaml',
    recurse => true,
    rmdirs  => false,
    type    => mtime,
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
}
# vim: sw=2:ai:nu expandtab
