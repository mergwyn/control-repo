# profile/manifests/platform/baseline/debian/virtual/lxc_masked_services.pp
class profile::platform::baseline::debian::virtual::lxc_masked_services {
  $masked_services = [
    'nvmf-autoconnect.service',
    'openipmi.service',
  ]

  $masked_services.each |String $svc| {
    exec { "mask-${svc}":
      command => "systemctl mask ${svc}",
      unless  => "systemctl is-enabled ${svc} 2>/dev/null | grep -q masked",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }
}
