#

class profile::virtual::docker {

  #include ::snapd
  #$snappackages = [ 'frr' ]
  #package { $snappackages:
  #  ensure   => present,
  #  provider => snap,
  #}
  # Docker

#sudo add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#   $(lsb_release -cs) \
#   stable"

  apt::source { 'docker':
    comment  => 'Docker Repository',
    location => 'https://download.docker.com/linux/ubuntu',
    #release  => $release,
    repos    => 'docker',
    key      => {
      'id'     => '9DC858229FC7DD38854AE2D88D81803C0EBFCD88',
      'server' => 'https://download.docker.com/linux/ubuntu/gpg',
    },
  }
  $aptpackages = [
    #'apt-transport-https',
    #'ca-certificates',
    #'curl',
    #'software-properties-common',
    'docker_ce',
  ]
  package { $aptpackages: ensure   => present, }

}
#
# vim: sw=2:ai:nu expandtab
