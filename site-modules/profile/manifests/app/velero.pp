# @summary velero backup (k8s)
#
class profile::app::velero (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/velero"

  exec { 'install-velero':
    command => @(END),
      curl -fsSL https://github.com/vmware-tanzu/velero/releases/download/v${version}/velero-v${version}-linux-amd64.tar.gz \
        | tar -xz --strip-components=1 -C ${bin_dir} velero-v${version}-linux-amd64/velero
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
