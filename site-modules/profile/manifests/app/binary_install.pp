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
#   defaults to installing if binary dies not exist.
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
# @example Install kubectl
#   profile::app::binary_install { 'kubectl':
#     version     => '1.35.1',
#     binary      => 'kubectl',
#     url         => 'https://dl.k8s.io/release/v1.35.1/bin/linux/amd64/kubectl',
#     version_cmd => 'kubectl version --client --short',
#   }
#
# @example Install kubectx (no version command)
#   profile::app::binary_install { 'kubectx':
#     version     => '0.9.4',
#     binary      => 'kubectx',
#     url         => 'https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx',
#   }
#
define profile::app::binary_install (
  String[1]            $version,
  Stdlib::HTTPUrl      $url,
  String[1]            $binary,
  String[1]            $version_cmd  = "echo ${version}",
  Boolean              $tarball      = false,
  Stdlib::Absolutepath $install_dir  = '/usr/local/bin',
  Optional[String[1]]  $tar_extract  = undef,
) {
  $bin = "${install_dir}/${binary}"

  if $tarball {
    $cmd = @("END")
      set -e
      curl -fsSL ${url} -o /tmp/${title}.tar.gz
      tar -xzf /tmp/${title}.tar.gz --strip-components=1-C ${install_dir} ${tar_extract}
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
    command => "sh -c '${cmd}'",
    path    => ['/usr/bin', '/bin', $install_dir],
    require => Package['curl'],
    # Skip execution if binary exists and version matches
    unless  => @("END"),
                sh -c '
                  if test -x ${bin};
                  then ${version_cmd} 2>/dev/null | grep -q ${version};
                  else exit 1;
                  fi
                '
                | - END
  }
}
