# @summary Puppet repo spec
# 
# @param release
#   release
class profile::openvox::repo (
  String $release = $facts['os']['distro']['codename'],
) {
  $ver = split($server_facts['serverversion'], '\.')
  $version = $ver[0]

  $arch =  $facts['os']['architecture']
  case $arch {
    'i386':  { $release = 'xenial' }
    'amd64': { $release }
    default: { notify { "Unexpected arch ${arch} for openvox repo": withpath => true } }
  }

  include apt

  $os_name = downcase($facts['os']['name'])
  apt::source { 'openvox8-release':
    comment  => "OpenVox 8 ${os_name}${facts['os']['release']['major']} Repository",
    location => 'https://apt.voxpupuli.org',
    release  => "${os_name}${facts['os']['release']['major']}",
    repos    => "openvox${version}",
    key      => {
      'name'   => 'openvox-keyring.gpg',
      'source' => 'https://apt.voxpupuli.org/openvox-keyring.gpg',
    },
  }

#  apt::source { 'puppet':
#    comment  => "Puppet ${version} ${release} Repository",
#    location => 'http://apt.puppetlabs.com',
#    release  => $release,
#    repos    => "puppet${version}",
#    key      => {
#      name   => 'puppetlabs-keyring.gpg',
#      source => 'https://apt.puppetlabs.com/keyring.gpg',
#    },
#  }

  $aptdir = '/etc/apt/sources.list.d'
  $purgelist = [
    "${aptdir}/puppet-release.list",
    "${aptdir}/puppet5.list",
    "${aptdir}/puppet6.list",
    "${aptdir}/puppet7.list",
    "${aptdir}/puppet5.list.distUpgrade",
    "${aptdir}/pc_repo.list",
    "${aptdir}/pc_repo.list.save",
    "${aptdir}/pc_repo.list.distUpgrade",
    "${aptdir}/puppetlabs-pc1.list",
    "${aptdir}/puppetlabs-pc1.list.dpkg-old",
  ]
  file { $purgelist: ensure => absent }
}
