# @summary development server
class role::development {
  include profile::platform::baseline
  include profile::domain::sso
# TODO: git, others etc?
}
