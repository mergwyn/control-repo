#

class profile::base::ssh_server {
  include '::ssh'

  exec { 'client_keys':
    command => '/usr/bin/ssh-keygen -q -N "" -f /root/.ssh/id_rsa -t rsa',
    creates => '/root/.ssh/id_rsa',
  }
}
# vim: nu sw=2 ai expandtab
