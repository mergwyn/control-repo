#
class profile::platform::baseline::debian::autofs {

  include autofs

  autofs::mount { 'net':
    mount   => '/net',
    options => '-hosts'
  }
}
