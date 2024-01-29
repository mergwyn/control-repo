#
#
class profile::puppet::repo (
  String $release = $facts['os']['distro']['codename'],
) {

  
  $ver = split($::serverversion, '\.')
  $version = $ver[0]

  $arch =  $facts['os']['architecture']
  case $arch {
    'i386':  { $release = 'xenial' }
    'amd64': { $release }
    default: { notify { "Unexpected arch ${arch} for puppet repo": withpath => true } }
  }
  apt::source { 'puppet':
    comment  => "Puppet ${version} ${release} Repository",
    location => 'http://apt.puppetlabs.com',
    release  => $release,
    repos    => "puppet${version}",
    key      => {
      'id'     => 'D6811ED3ADEEB8441AF5AA8F4528B6CD9E61EF26',
      'server' => 'pgp.mit.edu',
    },
  }
  $aptdir = '/etc/apt/sources.list.d'
  $purgelist = [
    "${aptdir}/puppet5.list",
    "${aptdir}/puppet6.list",
    "${aptdir}/puppet5.list.distUpgrade",
    "${aptdir}/pc_repo.list",
    "${aptdir}/pc_repo.list.save",
    "${aptdir}/pc_repo.list.distUpgrade",
    "${aptdir}/puppetlabs-pc1.list",
    "${aptdir}/puppetlabs-pc1.list.dpkg-old",
  ]
  file { $purgelist: ensure => absent }
}
