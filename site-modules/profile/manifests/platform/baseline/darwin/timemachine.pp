#
#
class profile::platform::baseline::darwin::timemachine (
  Integer $quota = 300*1024, 
) {

# TODO: tmutil setdestination afp://user[:pass]@host/share
# TODO: tmutil setexclusion [-p] <item> (check with 'tmutil isexcluded')

  exec {"set timemachine quota to ${quota}":
    path    => $facts['path'],
    onlyif  => "test `defaults read /Library/Preferences/com.apple.TimeMachine MaxSize 2>/dev/null` -ne ${quota}",
    command => "defaults write /Library/Preferences/com.apple.TimeMachine MaxSize ${quota}",
  }

}
