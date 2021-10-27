#
#
class profile::puppet::repo {

  $arch =  $::facts['os']['architecture']
  case $arch {
    'i386':  { $release = 'xenial' }
    'amd64': { $release = $facts['os']['distro']['codename']}
    default: { notify { "Unexpected arch ${arch} for puppet repo": withpath => true } }
  }
  apt::source { 'puppet6':
    comment  => "Puppet 6 ${release} Repository",
    location => 'http://apt.puppetlabs.com',
    release  => $release,
    repos    => 'puppet6',
    key      => {
      'id'     => 'D6811ED3ADEEB8441AF5AA8F4528B6CD9E61EF26',
      'server' => 'pgp.mit.edu',
    },
  }
  $aptdir = '/etc/apt/sources.list.d'
  $purgelist = [
    "${aptdir}/puppet5.list",
    "${aptdir}/puppet5.list.distUpgrade",
    "${aptdir}/pc_repo.list",
    "${aptdir}/pc_repo.list.save",
    "${aptdir}/pc_repo.list.distUpgrade",
    "${aptdir}/puppetlabs-pc1.list",
    "${aptdir}/puppetlabs-pc1.list.dpkg-old",
  ]
  file { $purgelist: ensure => absent }
}
