# @summary userss required for darwin

class  profile::platform::baseline::users::darwin {

  $home = '/Users/brew'

  user {'brew':
    gid        => 'admin',
    password   => lookup('secrets::brew'),
    iterations => 86956,
    salt       => 'b78fbae626c563458942fea9b35f160ab02274e8e1c6b2403b9c7c93785a3915',
    home       => $home,
  }

  file { $home:
    ensure  => directory,
    owner   => 'brew',
    group   => 'admin',
    require => User[brew],
  }

}
