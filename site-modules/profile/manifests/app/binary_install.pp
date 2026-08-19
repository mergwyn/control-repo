# @summary Install a standalone binary or script from a URL, with optional stamping
#
# Downloads and installs a single binary or archive into a target directory.
# Installation is skipped if the binary exists and the reported version matches.
# Scripts can be stamped with the version string to allow idempotent updates.
#
# @param version
#   Expected version string used for idempotency checks.
#
# @param url
#   HTTP(S) URL of the binary, script, or archive to download.
#
# @param binary
#   Name of the binary/script to install (no path). Can be a single String or an Array
#   of Strings when installing multiple binaries from the same archive.
#
# @param version_cmd
#   Command used to output the installed version. Defaults to 'echo ${version}'.
#   When installing multiple binaries this command will be executed as-is and is
#   expected to work for the primary binary (first in the list).
#
# @param archive
#   Archive format of the download. Supported values are:
#     none   - direct binary/script download
#     tar.gz - gzip-compressed tar archive
#     zip    - zip archive
#
# @param archive_extract
#   Path inside the archive to extract. Can be a single String or an Array of
#   Strings mapping one-to-one to `binary` when installing multiple binaries.
#   Required when archive is not 'none'.
#
# @param env_vars
#   Optional array of environment variables to pass to the `exec` command.
#
# @param stamp
#   Whether to append a version stamp to a script to allow update detection.
#
define profile::app::binary_install (
  String[1]                                      $version,
  Stdlib::HTTPUrl                                $url,
  Variant[String[1], Array[String[1]]]           $binary,
  String[1]                                      $version         = "echo ${version}",
  Enum['none', 'tar.gz', 'zip']                  $archive         = 'none',
  Stdlib::Absolutepath                           $install_dir     = '/usr/local/bin',
  Optional[Variant[String[1], Array[String[1]]]] $archive_extract = undef,
  Optional[Array[String[1]]]                     $env_vars        = undef,
  Boolean                                        $stamp           = false,
) {
  # Normalize binary to an array.
  case $binary {
    Array[String[1]]: { $binaries = $binary }
    default:          { $binaries = [$binary] }
  }

  $bins = $binaries.map |$b| { "${install_dir}/${b}" }

  # Normalize archive_extract to an array when supplied.
  if $archive_extract == undef {
    $archive_extract_list = undef
  } else {
    case $archive_extract {
      Array[String[1]]: { $archive_extract_list = $archive_extract }
      default:          { $archive_extract_list = [$archive_extract] }
    }
  }

  # Validate arguments.
  if $archive != 'none' and $archive_extract_list == undef {
    fail('archive_extract must be defined when archive is not none')
  }

  if $archive != 'none' and $archive_extract_list != undef and size($archive_extract_list) != size($binaries) {
    fail('When installing multiple binaries from an archive, archive_extract must contain the same number of entries as binary')
  }

  if $archive == 'none' and size($binaries) > 1 {
    fail('Installing multiple binaries is only supported when downloading an archive')
  }

  # Ensure required download/archive tools are available.
  package { 'curl':
    ensure => installed,
  }

  if $archive == 'zip' {
    package { 'unzip':
      ensure => installed,
    }

    $install_require = [
      Package['curl'],
      Package['unzip'],
    ]
  } else {
    $install_require = Package['curl']
  }

  # Build archive move commands.
  if $archive != 'none' {
    if $archive_extract_list == undef {
      fail('archive_extract_list should never be undef here')
    }

    $pairs = zip($binaries, $archive_extract_list)

    $mv_lines = $pairs.map |$pair| {
      $bin_name  = $pair[0]
      $extract_p = $pair[1]

      @("END")
        chmod +x "/tmp/${title}-extract/${extract_p}"
        mv -f "/tmp/${title}-extract/${extract_p}" "${install_dir}/${bin_name}"
        | END
    }.join("\n")
  }

  # Build the install command.
  case $archive {
    'tar.gz': {
      $cmd = @("END")
        set -e
        rm -rf "/tmp/${title}-extract"
        mkdir -p "/tmp/${title}-extract"

        curl -fsSL "${url}" -o "/tmp/${title}.tar.gz"
        tar -xzf "/tmp/${title}.tar.gz" -C "/tmp/${title}-extract"

        ${mv_lines}

        rm -rf "/tmp/${title}.tar.gz" "/tmp/${title}-extract"
        | END
    }

    'zip': {
      $cmd = @("END")
        set -e
        rm -rf "/tmp/${title}-extract"
        mkdir -p "/tmp/${title}-extract"

        curl -fsSL "${url}" -o "/tmp/${title}.zip"
        unzip -q "/tmp/${title}.zip" -d "/tmp/${title}-extract"

        ${mv_lines}

        rm -rf "/tmp/${title}.zip" "/tmp/${title}-extract"
        | END
    }

    default: {
      $bin = $bins[0]

      $cmd = @("END")
        set -e
        curl -fsSL "${url}" -o "${bin}.tmp"
        chmod +x "${bin}.tmp"
        mv -f "${bin}.tmp" "${bin}"
        | END
    }
  }

  # If stamping, append the version string to each script.
  if $stamp {
    $binaries.each |$bname| {
      exec { "stamp-${title}-${bname}":
        command => "printf '# version: %s\\n' '${version}' >> '${install_dir}/${bname}'",
        path    => ['/usr/bin', '/bin', $install_dir],
        onlyif  => "test -x '${install_dir}/${bname}' && ! tail -1 '${install_dir}/${bname}' | grep -F -q -- '${version}'",
        require => Exec["install-${title}"],
      }
    }

    $version_cmd_real = "tail -1 '${bins[0]}'"
  } else {
    $version_cmd_real = $version_cmd
  }

  # Ensure HOME exists in the exec environment unless explicitly supplied.
  if $env_vars == undef {
    $exec_env = ['HOME=/root']
  } else {
    $home_vars = $env_vars.filter |$e| { $e =~ /^HOME=/ }

    if size($home_vars) > 0 {
      $exec_env = $env_vars
    } else {
      $exec_env = $env_vars + ['HOME=/root']
    }
  }

  exec { "install-${title}":
    command     => "sh -c '${cmd}'",
    path        => ['/usr/bin', '/bin', $install_dir],
    require     => $install_require,
    environment => $exec_env,

    # Skip installation if the primary binary exists and reports the
    # requested version.
    unless      => @("END"),
      sh -c '
        if test -x "${bins[0]}"; then
          echo "binary_install[${title}]: found=$(command -v ${binaries[0]} 2>&1), version=$(${version_cmd_real} 2>&1)" >&2
          ${version_cmd_real} 2>&1 | grep -F -q -- "${version}"
        else
          exit 1
        fi
      '
      | - END
  }
}
