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
#   Name of the binary/script to install (no path). Can be a single String or an Array
#   of Strings when installing multiple binaries from the same tarball.
#
# @param version_cmd
#   Command used to output the installed version. Defaults to 'echo ${version}'.
#   When installing multiple binaries this command will be executed as-is and is
#   expected to work for the primary binary (first in the list).
#
# @param tarball
#   Whether the download is a tarball containing the binary/script.
#
# @param tar_extract
#   Path inside the tarball to extract. Can be a single String or an Array of
#   Strings mapping one-to-one to `binary` when installing multiple binaries.
#   Required when `tarball` is true.
#
# @param env_vars
#   Optional hash of environment variables to pass to the `exec` command.
#
# @param stamp
#   Whether to append a version stamp to a script to allow update detection.
#
define profile::app::binary_install (
  String[1]                                    $version,
  Stdlib::HTTPUrl                              $url,
  Variant[String[1], Array[String[1]]]         $binary,
  String[1]                                    $version_cmd  = "echo ${version}",
  Boolean                                      $tarball      = false,
  Stdlib::Absolutepath                         $install_dir  = '/usr/local/bin',
  Optional[Variant[String[1], Array[String[1]]]] $tar_extract  = undef,
  Optional[Array]                              $env_vars     = undef,
  Boolean                                      $stamp        = false,
) {
  # Normalize binary list to an array and build install paths
  # Normalize to an array using stdlib's wrap() to support multiple Puppet/stdlib versions
  $binaries = wrap($binary)
  $bins = $binaries.map |$b| { "${install_dir}/${b}" }

  if $tarball and $tar_extract == undef {
    fail('tar_extract must be defined when tarball is true')
  }

  # Normalize tar_extract to an array when provided
  if $tar_extract == undef {
    $tar_extract_list = undef
  } else {
    $tar_extract_list = wrap($tar_extract)
  }

  # If we have multiple binaries, require tar_extract to map to them when using a tarball
  if $tarball and $tar_extract_list != undef and size($tar_extract_list) != size($binaries) {
    fail('When installing multiple binaries from a tarball, tar_extract must be an array with the same number of entries as binaries')
  }

  # Prevent non-tarball installs from attempting to install multiple binaries from a single URL
  if ! $tarball and size($binaries) > 1 {
    fail('Installing multiple binaries is only supported when downloading a tarball')
  }

  # Determine if --strip-components=1 is needed for tarballs
  if $tar_extract_list and $tar_extract_list[0] =~ /\// {
    $strip_opt = '--strip-components=1'
  } else {
    $strip_opt = ''
  }

  # Build install command(s)
  if $tarball {
    # Build commands to move each requested file from the extracted tree to its final path
    if $tar_extract_list == undef {
      fail('tar_extract_list should never be undef here')
    }

    $pairs = zip($binaries, $tar_extract_list)
    $mv_lines = $pairs.map |$pair| {
      $bin_name   = $pair[0]
      $extract_p  = $pair[1]
      "chmod +x /tmp/${title}-extract/${extract_p}\n      mv -f /tmp/${title}-extract/${extract_p} ${install_dir}/${bin_name}"
    }.join("\n      ")

    $cmd = @("END")
      set -e
      mkdir -p /tmp/${title}-extract
      curl -fsSL ${url} -o /tmp/${title}.tar.gz
      tar -xzf /tmp/${title}.tar.gz -C /tmp/${title}-extract
      ${mv_lines}
      rm -rf /tmp/${title}.tar.gz /tmp/${title}-extract
      END
  } else {
    $bin = $bins[0]
    $cmd = @("END")
      set -e
      curl -fsSL ${url} -o ${bin}.tmp
      chmod +x ${bin}.tmp
      mv -f ${bin}.tmp ${bin}
      END
  }

  # If stamping, append the version string to the script(s)
  if $stamp {
    # Create a stamp exec for each binary
    $binaries.each |$bname| {
      exec { "stamp-${title}-${bname}":
        command => "printf '# version: %s\\n' '${version}' >> '${install_dir}/${bname}'",
        path    => ['/usr/bin', '/bin', $install_dir],
        onlyif  => "test -x ${install_dir}/${bname} && ! tail -1 ${install_dir}/${bname} | grep -q '${version}'",
        require => Exec["install-${title}"],
      }
    }
    # When stamping, use the tail of the primary binary as version_cmd
    $version_cmd_real = "tail -1 ${bins[0]}"
  } else {
    $version_cmd_real = $version_cmd
  }

  # Main install exec
  exec { "install-${title}":
    command     => "sh -c '${cmd}'",
    path        => ['/usr/bin', '/bin', $install_dir],
    require     => Package['curl'],
    environment => $env_vars,
    # Skip execution if primary binary exists and version matches
    unless      => @("END"),
      sh -c '
        if test -x ${bins[0]};
        then ${version_cmd_real} 2>/dev/null | grep -q ${version};
        else exit 1;
        fi
      '
      | - END
  }
}
