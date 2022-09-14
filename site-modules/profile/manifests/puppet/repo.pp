#
#
class profile::puppet::repo (
  String $release = $facts['os']['distro']['codename'],
) {

  $arch =  $::facts['os']['architecture']
  case $arch {
    'i386':  { $release = 'xenial' }
    'amd64': { $release }
    default: { notify { "Unexpected arch ${arch} for puppet repo": withpath => true } }
  }
  $collection = lookup('defaults::puppetcollection')
  apt::source { $collection :
    comment  => "${collection} ${release} Repository",
    location => 'http://apt.puppetlabs.com',
    release  => $release,
    repos    => $collection,
    key      => {
      'id'     => 'D6811ED3ADEEB8441AF5AA8F4528B6CD9E61EF26',
      'server' => 'pgp.mit.edu',
    },
  }
  $aptdir = '/etc/apt/sources.list.d'
  $purgelist = [
    "${aptdir}/puppet6.list",
    "${aptdir}/puppet6.list.distUpgrade",
    "${aptdir}/pc_repo.list",
    "${aptdir}/pc_repo.list.save",
    "${aptdir}/pc_repo.list.distUpgrade",
    "${aptdir}/puppetlabs-pc1.list",
    "${aptdir}/puppetlabs-pc1.list.dpkg-old",
  ]
  file { $purgelist: ensure => absent }
}
