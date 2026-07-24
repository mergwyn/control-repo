# @summary Manage core macOS configuration on Puppet-managed Mac endpoints.
#
# Replaces the retired `managedmac` module. Built from native resource
# types plus small `exec` wrappers, following the role/profile pattern
# used elsewhere in this control repo.
#
# @param loginwindow_text
#   Text shown at the login window (e.g. hostname).
# @param homebrew_packages
#   Homebrew formula names to install. Requires the `call/homebrew` module.
# @param ad_domain
#   Active Directory domain to bind to. Leave undef to skip AD binding.
# @param ad_ou
#   Organizational Unit for the computer object.
# @param ad_admin_user
#   AD account with rights to bind computers to the domain.
# @param ad_admin_password
#   Password for $ad_admin_user. Supply via eyaml.
# @param ad_computer_name
#   Computer object name to register in AD. Defaults to the local hostname.
# @param ad_mount_style
#   Network home protocol: 'smb' or 'afp'.
# @param ad_create_mobile_account
#   Create a local mobile account on first network login.
# @param ad_warn_before_mobile_account
#   Warn the user before creating a mobile account.
# @param ad_force_home_local
#   Force the home directory to the local disk rather than the network share.
# @param ad_use_windows_unc_path
#   Use a Windows UNC path for the network home location.
# @param ad_default_shell
#   Default login shell assigned to AD users.
# @param ad_uid_attribute
#   AD attribute mapped to the local UID.
# @param ad_gid_attribute
#   AD attribute mapped to the local primary GID.
# @param ad_ggid_attribute
#   AD attribute mapped to the local group GID.
# @param ad_admin_group_list
#   AD groups granted local admin rights, e.g. 'DOMAIN\\Domain Admins'.
# @param ntp_servers
#   NTP servers. Only the first is used; `systemsetup` supports one active server.
# @param tm_host
#   Time Machine network destination hostname. Leave undef to skip.
# @param tm_share
#   AFP share name on $tm_host.
# @param tm_user
#   Username for the Time Machine destination.
# @param tm_password
#   Password for $tm_user. Supply via eyaml.
# @param tm_quota_mb
#   Time Machine backup size limit, in megabytes. 0 disables the quota check.
# @param tm_exclusions
#   Absolute paths to exclude from Time Machine backups.
#
class profile::os::macos (
  String                          $loginwindow_text     = $trusted['hostname'],
  Array[String]                   $homebrew_packages     = [],
  Optional[String]                $ad_domain             = $trusted['domain'],,
  Optional[String]                $ad_ou                 = undef,
  Optional[String]                $ad_admin_user         = undef,
  Optional[Sensitive[String]]     $ad_admin_password     = undef,
  String                          $ad_computer_name      = $trusted['hostname'],
  Enum['smb', 'afp']              $ad_mount_style        = 'smb',
  Boolean                         $ad_create_mobile_account       = true,
  Boolean                         $ad_warn_before_mobile_account  = true,
  Boolean                         $ad_force_home_local            = true,
  Boolean                         $ad_use_windows_unc_path        = true,
  String                          $ad_default_shell      = '/bin/bash',
  String                          $ad_uid_attribute      = 'uidNumber',
  String                          $ad_gid_attribute      = 'gidNumber',
  String                          $ad_ggid_attribute     = 'gidNumber',
  Array[String]                   $ad_admin_group_list   = [],
  Array[String]                   $ntp_servers           = ['time.apple.com'],
  Optional[String]                $tm_host               = undef,
  Optional[String]                $tm_share              = undef,
  Optional[String]                $tm_user               = undef,
  Optional[Sensitive[String]]     $tm_password           = undef,
  Integer                         $tm_quota_mb           = 0,
  Array[String]                   $tm_exclusions         = [],
) {
  # --- Login window ----------------------------------------------------------

  exec { 'set loginwindow text':
    path    => $facts['path'],
    onlyif  => "test \"$(defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null)\" != \"${loginwindow_text}\"",
    command => "defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText \"${loginwindow_text}\"",
  }

  # --- Homebrew ----------------------------------------------------------------

  package { $homebrew_packages:
    ensure   => present,
    provider => 'homebrew',
  }

  # --- Active Directory --------------------------------------------------------

  if $ad_domain {
    unless $ad_admin_user and $ad_admin_password {
      fail('profile::os::macos: ad_domain is set but ad_admin_user/ad_admin_password are missing')
    }

    $ad_mobile_flag   = $ad_create_mobile_account ? { true => 'enable', false => 'disable' }
    $ad_confirm_flag  = $ad_warn_before_mobile_account ? { true => 'enable', false => 'disable' }
    $ad_localhome_flag = $ad_force_home_local ? { true => 'enable', false => 'disable' }
    $ad_unc_flag      = $ad_use_windows_unc_path ? { true => 'enable', false => 'disable' }
    $ad_protocol      = upcase($ad_mount_style)
    $ad_groups        = $ad_admin_group_list.join(',')

    $ad_command_parts = [
      'dsconfigad', '-force', '-add', $ad_domain,
      '-computer', $ad_computer_name,
      '-ou', "\"${ad_ou}\"",
      '-username', $ad_admin_user,
      '-password', "'${ad_admin_password.unwrap}'",
      '-mobile', $ad_mobile_flag,
      '-mobileconfirm', $ad_confirm_flag,
      '-localhome', $ad_localhome_flag,
      '-useuncpath', $ad_unc_flag,
      '-protocol', $ad_protocol,
      '-shell', $ad_default_shell,
      '-uid', $ad_uid_attribute,
      '-gid', $ad_gid_attribute,
      '-ggid', $ad_ggid_attribute,
      '-groups', "\"${ad_groups}\"",
    ]

    # NOTE: these flags are only applied at initial bind time, since the
    # exec is guarded by "unless already bound". Changing them later
    # requires either an unbind/rebind or a manual dsconfigad run.
    exec { 'bind to active directory':
      path    => $facts['path'],
      unless  => 'dsconfigad -show | grep -q "Active Directory Domain"',
      command => $ad_command_parts.join(' '),
    }
  }

  # --- Network time ------------------------------------------------------------

  $primary_ntp_server = $ntp_servers[0]

  exec { 'enable network time':
    path    => $facts['path'],
    unless  => 'systemsetup -getusingnetworktime | grep -q "On"',
    command => 'systemsetup -setusingnetworktime on',
  }

  exec { 'set network time server':
    path    => $facts['path'],
    onlyif  => "test \"$(systemsetup -getnetworktimeserver | awk '{print \$NF}')\" != \"${primary_ntp_server}\"",
    command => "systemsetup -setnetworktimeserver ${primary_ntp_server}",
    require => Exec['enable network time'],
  }

  # --- Time Machine --------------------------------------------------------------

  if $tm_host and $tm_share {
    unless $tm_user and $tm_password {
      fail('profile::os::macos: tm_host is set but tm_user/tm_password are missing')
    }

    exec { 'set timemachine destination':
      path    => $facts['path'],
      unless  => "tmutil destinationinfo | grep -q \"${tm_host}\"",
      command => "tmutil setdestination -a \"afp://${tm_user}:${tm_password.unwrap}@${tm_host}/${tm_share}\"",
    }
  }

  if $tm_quota_mb > 0 {
    exec { "set timemachine quota to ${tm_quota_mb}":
      path    => $facts['path'],
      onlyif  => "test \"$(defaults read /Library/Preferences/com.apple.TimeMachine MaxSize 2>/dev/null)\" -ne ${tm_quota_mb}",
      command => "defaults write /Library/Preferences/com.apple.TimeMachine MaxSize ${tm_quota_mb}",
    }
  }

  $tm_exclusions.each |String $item| {
    exec { "exclude ${item} from timemachine":
      path    => $facts['path'],
      unless  => "tmutil isexcluded \"${item}\" | grep -q '\\[Excluded\\]'",
      command => "tmutil addexclusion \"${item}\"",
    }
  }
}
