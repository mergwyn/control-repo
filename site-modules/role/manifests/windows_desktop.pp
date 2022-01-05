#
class role::windows_desktop {
  include profile::platform::baseline
  include profile::app::todobackup
}
