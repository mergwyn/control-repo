# @summary Install a standalone binary or script from a URL, with optional stamping
#
# Downloads and installs a single binary or tarball into a target directory.
# Installation is skipped if the binary exists and the reported version matches.
# Scripts can be stamped with the version string to allow idempotent updates.
#
# @param version
#   Expected version string used for idempotency checks.
#
# @param url
#   HTTP(S) URL of the binary, script, or tarball to download.
#
# @param binary
#   Name of the binary/script to install (no path).
#
# @param version_cmd
#   Command used to output the installed version. Defaults to 'echo ${version}'.
#
# @param tarball
#   Whether the download is a tarball containing the binary/script.
#
# @param tar_extract
#   Path inside the tarball to extract (required when tarball is true).
#
# @param env_vars
#   Optional hash of environment variables to pass to the `exec` command.
#
# @param stamp
#   Whether to append a version stamp to a script to allow update detection.
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
  Boolean              $stamp        = false,
) {
  $bin = "${install_dir}/${binary}"

  if $tarball and $tar_extract == undef {
    fail('tar_extract must be defined when tarball is true')
  }

  # Determine if --strip-components=1 is needed for tarballs
  if $tar_extract and $tar_extract =~ /\// {
    $strip_opt = '--strip-components=1'
  } else {
    $strip_opt = ''
  }

  # Command to download/install the binary or tarball.
  # In both cases we download/extract to a temporary location first, then
  # atomic-swap (mv) into the final path. This avoids curl(23)/ETXTBSY when
  # the target binary is locked by a running daemon, since mv replaces the
  # directory entry without truncating the existing file.
  if $tarball {
    $tar_src = "/tmp/${title}-extract/${tar_extract}"
    $cmd = @("END")
      set -e
      mkdir -p /tmp/${title}-extract
      curl -fsSL ${url} -o /tmp/${title}.tar.gz
      tar -xzf /tmp/${title}.tar.gz -C /tmp/${title}-extract
      chmod +x ${tar_src}
      mv -f ${tar_src} ${bin}
      rm -rf /tmp/${title}.tar.gz /tmp/${title}-extract
      END
  } else {
    $cmd = @("END")
      set -e
      curl -fsSL ${url} -o ${bin}.tmp
      chmod +x ${bin}.tmp
      mv -f ${bin}.tmp ${bin}
      END
  }

  # If stamping, append the version string to the script
  if $stamp {
    exec { "stamp-${title}":
      command => "printf '# version: %s\\n' '${version}' >> '${bin}'",
      path    => ['/usr/bin', '/bin', $install_dir],
      onlyif  => "test -x ${bin} && ! tail -1 ${bin} | grep -q '${version}'",
      require => Exec["install-${title}"],
    }
    $version_cmd_real = "tail -1 ${bin}"
  } else {
    $version_cmd_real = $version_cmd
  }

  # Main install exec
  exec { "install-${title}":
    command     => "sh -c '${cmd}'",
    path        => ['/usr/bin', '/bin', $install_dir],
    require     => Package['curl'],
    environment => $env_vars,
    # Skip execution if binary/script exists and version matches
    unless      => @("END"),
      sh -c '
        if test -x ${bin};
        then ${version_cmd_real} 2>/dev/null | grep -q ${version};
        else exit 1;
        fi
      '
      | - END
  }
}
