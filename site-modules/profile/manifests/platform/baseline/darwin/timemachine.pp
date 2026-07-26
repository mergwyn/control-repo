# @summary Configure macOS Time Machine destination, quota, and exclusions.
#
# @param host
#   Time Machine network destination hostname. Leave undef to skip.
# @param share
#   AFP share name on $host.
# @param user
#   Username for the Time Machine destination.
# @param password
#   Password for $user. Supply via eyaml.
# @param quota_mb
#   Time Machine backup size limit, in megabytes. 0 disables the quota check.
# @param exclusions
#   Absolute paths to exclude from Time Machine backups.
#
class profile::platform::baseline::darwin::timemachine (
  Optional[String]   $host        = undef,
  Optional[String]   $share       = undef,
  Optional[String]   $user        = undef,
  Optional[String]   $password    = undef,
  Enum['smb', 'afp'] $mount_style = 'smb',
  Integer            $quota_mb    = 0,
  Array[String]      $exclusions  = [],
) {
  if $host and $share {
    unless $user and $password {
      fail('profile::os::macos::timemachine: host is set but user/password are missing')
    }

    exec { 'set timemachine destination':
      path    => $facts['path'],
      unless  => "tmutil destinationinfo | grep -iq \"${host}\"",
      command => "tmutil setdestination -a \"${mount_style}://${user}:${password.unwrap}@${host}/${share}\"",
    }
  }

  if $quota_mb > 0 {
    exec { "set timemachine quota to ${quota_mb}":
      path    => $facts['path'],
      onlyif  => "test \"$(defaults read /Library/Preferences/com.apple.TimeMachine MaxSize 2>/dev/null)\" -ne ${quota_mb}",
      command => "defaults write /Library/Preferences/com.apple.TimeMachine MaxSize ${quota_mb}",
    }
  }

  $exclusions.each |String $item| {
    exec { "exclude ${item} from timemachine":
      path    => $facts['path'],
      unless  => "tmutil isexcluded \"${item}\" | grep -q '\\[Excluded\\]'",
      command => "tmutil addexclusion \"${item}\"",
    }
  }
}
