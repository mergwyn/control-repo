# @summary Bind a macOS host to Active Directory.
#
# @param domain
#   Active Directory domain to bind to.
# @param ou
#   Organizational Unit for the computer object.
# @param admin_user
#   AD account with rights to bind computers to the domain. Supply via Hiera/eyaml.
# @param admin_password
#   Password for $admin_user. Supply via eyaml.
# @param computer_name
#   Computer object name to register in AD. Defaults to the local hostname.
# @param mount_style
#   Network home protocol: 'smb' or 'afp'.
# @param create_mobile_account
#   Create a local mobile account on first network login.
# @param warn_before_mobile_account
#   Warn the user before creating a mobile account.
# @param force_home_local
#   Force the home directory to the local disk rather than the network share.
# @param use_windows_unc_path
#   Use a Windows UNC path for the network home location.
# @param default_shell
#   Default login shell assigned to AD users.
# @param uid_attribute
#   AD attribute mapped to the local UID.
# @param gid_attribute
#   AD attribute mapped to the local primary GID.
# @param ggid_attribute
#   AD attribute mapped to the local group GID.
# @param admin_group_list
#   AD groups granted local admin rights, e.g. 'DOMAIN\\Domain Admins'.
#
class profile::platform::baseline::darwin::activedirectory (
  String                  $admin_user,
  Sensitive[String]       $admin_password,
  String                  $domain                     = $trusted['domain'],
  Optional[String]        $ou                         = undef,
  String                  $computer_name              = $trusted['hostname'],
  Enum['smb', 'afp']      $mount_style                = 'smb',
  Boolean                 $create_mobile_account       = true,
  Boolean                 $warn_before_mobile_account  = true,
  Boolean                 $force_home_local            = true,
  Boolean                 $use_windows_unc_path        = true,
  String                  $default_shell               = '/bin/bash',
  String                  $uid_attribute               = 'uidNumber',
  String                  $gid_attribute               = 'gidNumber',
  String                  $ggid_attribute              = 'gidNumber',
  Array[String]           $admin_group_list            = [],
) {
  $mobile_flag    = $create_mobile_account ? { true => 'enable', false => 'disable' }
  $confirm_flag   = $warn_before_mobile_account ? { true => 'enable', false => 'disable' }
  $localhome_flag = $force_home_local ? { true => 'enable', false => 'disable' }
  $unc_flag       = $use_windows_unc_path ? { true => 'enable', false => 'disable' }
  $protocol       = upcase($mount_style)
  $groups         = $admin_group_list.join(',')

  $command_parts = [
    'dsconfigad', '-force', '-add', $domain,
    '-computer', $computer_name,
    '-ou', "\"${ou}\"",
    '-username', $admin_user,
    '-password', "'${admin_password.unwrap}'",
    '-mobile', $mobile_flag,
    '-mobileconfirm', $confirm_flag,
    '-localhome', $localhome_flag,
    '-useuncpath', $unc_flag,
    '-protocol', $protocol,
    '-shell', $default_shell,
    '-uid', $uid_attribute,
    '-gid', $gid_attribute,
    '-ggid', $ggid_attribute,
    '-groups', "\"${groups}\"",
  ]

  # NOTE: these flags are only applied at initial bind time, since the
  # exec is guarded by "unless already bound". Changing them later
  # requires either an unbind/rebind or a manual dsconfigad run.
  exec { 'bind to active directory':
    path    => $facts['path'],
    unless  => 'dsconfigad -show | grep -q "Active Directory Domain"',
    command => $command_parts.join(' '),
  }
}
