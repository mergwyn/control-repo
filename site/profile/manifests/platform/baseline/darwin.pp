#

class profile::platform::baseline::darwin {

  include profile::platform::baseline::users::darwin
  include profile::platform::baseline::darwin::brew
  include profile::platform::baseline::darwin::packages

}
