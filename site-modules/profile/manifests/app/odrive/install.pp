# @summary defined type to install the agent and cli
#

define profile::app::odrive::install (
  $install_path,
) {

  if ! File[$install_path] {
    file { $install_path: ensure => directory, }
  }

  $app_source       = "https://dl.odrive.com/${title}-lnx-64"
  $app_archive      = sprintf('%s.tar.gz',basename($app_source))
  $app_archive_path = "${facts['puppet_vardir']}/${app_archive}"
  $creates_app      = "${install_path}/${title}"

  archive { $app_archive:
    path         => $app_archive_path,
    source       => $app_source,
    extract      => true,
    extract_path => $install_path,
    #creates      => $creates_app,
    cleanup      => false,
  }
}
