#
class role::windows_desktop {
  include profile::platform::baseline
  include profile::os::windows::dism
  include profile::os::windows::tasks
}
