# @summary Set the macOS login window text.
#
# @param text
#   Text displayed at the login window (e.g. hostname).
#
class profile::platform::baseline::darwin::loginwindow (
  String $text = $trusted['hostname'],
) {
  exec { 'set loginwindow text':
    path    => $facts['path'],
    onlyif  => "test \"$(defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null)\" != \"${text}\"",
    command => "defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText \"${text}\"",
  }
}
