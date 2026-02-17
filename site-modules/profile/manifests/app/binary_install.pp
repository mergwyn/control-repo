#
#
define profile::app::binary_install (
  String  $version,
  String  $url,
  String  $binary,
  String  $version_cmd,
  String  $bin_dir      = '/usr/local/bin',
  Boolean $tarball      = false,
  Optional[String] $tar_extract = undef
) {
  $bin = "${bin_dir}/${binary}"

  if $tarball {
    $cmd = @("END")
            set -e
            curl -fsSL ${url} -o /tmp/${title}.tar.gz
            tar -xzf /tmp/${title}.tar.gz -C ${bin_dir} ${tar_extract}
            chmod +x ${bin}
            rm -f /tmp/${title}.tar.gz
            | - END
  } else {
    $cmd = @("END")
            set -e
            curl -fsSL ${url} -o ${bin}
            chmod +x ${bin}
            | - END
  }

  exec { "install-${title}":
    command => "sh -c '${cmd}'",
    path    => ['/usr/bin', '/bin', $bin_dir],
    require => Package['curl'],
    unless  => "command -v ${binary} >/dev/null 2>&1 && ${version_cmd} 2>/dev/null | grep -q ${version}",
  }
}
