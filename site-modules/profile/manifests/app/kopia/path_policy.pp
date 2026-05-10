# @summary Manage kopia per-path snapshot hooks
#
# @param before_snapshot Array of commands to run before snapshotting this path
# @param after_snapshot Array of commands to run after snapshotting this path
#
define profile::app::kopia::path_policy (
  Optional[Array[String]] $before_snapshot = undef,
  Optional[Array[String]] $after_snapshot  = undef,
) {
  $path      = $title
  $path_safe = regsubst(regsubst($path, '/', '-', 'G'), '^-', '', 'G')
  $snapbefore = lookup('profile::app::kopia::client::snapbefore')
  $snapafter  = lookup('profile::app::kopia::client::snapafter')

  if $before_snapshot {
    $before_wrapper = "${snapbefore}/hook-${path_safe}"

    file { $before_wrapper:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => inline_template("#!/bin/bash\nset -e\n<%= @before_snapshot.join(\"\n\") %>\n"),
    }
    exec { "kopia-policy-before-${path}":
      command   => "/usr/bin/kopia policy set '${path}' --before-snapshot-root-action '${before_wrapper}'",
      unless    => "/usr/bin/kopia policy get '${path}' 2>/dev/null | grep -qF '${before_wrapper}'",
      subscribe => File[$before_wrapper],
      require   => File[$before_wrapper],
    }
  }

  if $after_snapshot {
    $after_wrapper = "${snapafter}/hook-${path_safe}"

    file { $after_wrapper:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => inline_template("#!/bin/bash\nset -e\n<%= @after_snapshot.join(\"\n\") %>\n"),
    }

    exec { "kopia-policy-after-${path}":
      command   => "/usr/bin/kopia policy set '${path}' --after-snapshot-root-action '${after_wrapper}'",
      unless    => "/usr/bin/kopia policy get '${path}' 2>/dev/null | grep -qF '${after_wrapper}'",
      subscribe => File[$after_wrapper],
      require   => File[$after_wrapper],
    }
  }
}
