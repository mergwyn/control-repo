# @summary Packages for Darwin
#
class profile::platform::baseline::darwin::packages {
# TODO add call to brew update and brew upgrade?

  $taps = [
    'git',
    'unison',
    'python@3.12',   # TODO convert to a fact
    'python-tk@3.12',
  ]
  package { $taps:
    provider => 'brew',
    ensure   => 'present'
  }
}
