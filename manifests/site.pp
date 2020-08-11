#

lookup('classes', Array[String], 'deep', []).contain
if $trusted['extensions']['pp_role'] {
  include "role::${$trusted['extensions']['pp_role']}"
} else {
  warn("pp_role is not set")
}

node default {

}
