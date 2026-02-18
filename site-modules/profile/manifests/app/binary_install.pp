# @summary Install a standalone binary from a URL
#
# Downloads and installs a single binary or tarball into a target directory.
# Installation is skipped if the binary exists and the reported version matches.
#
# @param version
#   Expected version string used for idempotency checks.
#
# @param url
#   HTTP(S) URL of the binary or tarball to download.
#
# @param binary
#   Name of the binary to install (no path).
#
# @param version_cmd
#   Command used to output the installed version. The output is matched
#   against `version` using grep.
#   Defaults to installing if binary does not exist.
#
# @param install_dir
#   Absolute directory where the binary will be installed.
#
# @param tarball
#   Whether the download is a tarball containing the binary.
#
# @param tar_extract
#   Path inside the tarball to extract (required when tarball is true).
#
# @param env_vars
#   Optional hash of environment variables to pass to the `exec` command.
#
define profile::app::binary_install (
  String[1]            $version,
  Stdlib::HTTPUrl      $url,
  String[1]            $binary,
  String[1]            $version_cmd  = "echo ${version}",
  Boolean              $tarball      = false,
  Stdlib::Absolutepath $install_dir  = '/usr/local/bin',
  Optional[String[1]]  $tar_extract  = undef,
  Optional[Array]      $env_vars     = undef,
) {
  $bin = "${install_dir}/${binary}"

  if $tarball and $tar_extract == undef {
    fail('tar_extract must be defined when tarball is true')
  }

  # Determine if --strip-components=1 is needed
  $strip_opt = $tar_extract =~ /\// ? '--strip-components=1' : ''

  if $tarball {
    $cmd = @("END")
      set -e
      curl -fsSL ${url} -o /tmp/${title}.tar.gz
      tar -xzf /tmp/${title}.tar.gz ${strip_opt} -C ${install_dir} ${tar_extract}
      chmod +x ${bin}
      rm -f /tmp/${title}.tar.gz
      END
  } else {
    $cmd = @("END")
      set -e
      curl -fsSL ${url} -o ${bin}
      chmod +x ${bin}
      END
  }

  exec { "install-${title}":
    command     => "sh -c '${cmd}'",
    path        => ['/usr/bin', '/bin', $install_dir],
    require     => Package['curl'],
    environment => $env_vars,
    # Skip execution if binary exists and version matches
    unless      => @("END"),
      sh -c '
        if test -x ${bin};
        then ${version_cmd} 2>/dev/null | grep -q ${version};
        else exit 1;
        fi
      '
      | - END
  }
}
