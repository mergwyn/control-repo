# @summary Installs and manages Ollama on macOS (Darwin) hosts.
#
# Installs the Ollama CLI via Homebrew and configures a launchd
# daemon so `ollama serve` runs continuously in the background.
# This class is Darwin-only and fails on any other OS family, so
# apply it only to nodes/roles that are actually Macs.
#
# @param user
#   macOS user account that owns the models directory and runs the
#   Ollama process.
#
# @param ensure
#   Desired state of the ollama Homebrew package.
#
# @param listen_host
#   Host/IP the Ollama API binds to.
#
# @param listen_port
#   Port the Ollama API listens on.
#
# @param models_dir
#   Directory where Ollama stores downloaded models.
#
# @param service_ensure
#   Ensure state for the launchd job.
#
# @param service_enable
#   Whether the launchd job is enabled (loaded at boot).
#
# @param listen_origins
#   Value for OLLAMA_ORIGINS, controlling which request origins the
#   API accepts. Use '*' to allow all (matches prior manual setup).
#
class profile::app::ollama (
  String[1]                            $user            = 'gary',
  Enum['present', 'installed', 'latest'] $ensure         = 'installed',
  Stdlib::Host                         $listen_host      = '127.0.0.1',
  Stdlib::Port                         $listen_port      = 11434,
  Stdlib::Absolutepath                 $models_dir       = '/Users/Shared/ollama/models',
  Enum['running', 'stopped']           $service_ensure   = 'running',
  Boolean                              $service_enable   = true,
  String[1]                            $listen_origins   = '*',
) {
  # This profile only makes sense on macOS. Fail loudly rather than
  # silently no-op, so a misapplied role is caught immediately.
  if $facts['os']['family'] != 'Darwin' {
    fail("profile::app::ollama supports Darwin only; got '${facts['os']['family']}' on ${facts['networking']['fqdn']}")
  }

  # Homebrew installs to different prefixes on Apple Silicon vs Intel.
  # Requires the puppetlabs/homebrew module for the 'homebrew' package
  # provider; adjust if a different Homebrew module is in use.
  $homebrew_prefix = $facts['os']['architecture'] ? {
    'aarch64' => '/opt/homebrew',
    'arm64'   => '/opt/homebrew',
    default   => '/usr/local',
  }
  $ollama_bin = "${homebrew_prefix}/bin/ollama"

  package { 'ollama':
    ensure   => $ensure,
    provider => 'homebrew',
  }

  file { $models_dir:
    ensure => directory,
    owner  => $user,
    group  => '513',
    mode   => '0750',
  }

  $plist_path = '/Library/LaunchDaemons/com.ollama.serve.plist'

  file { $plist_path:
    ensure  => file,
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    content => epp('profile/ollama_launchd.plist.epp', {
      'user'           => $user,
      'ollama_bin'     => $ollama_bin,
      'listen_host'    => $listen_host,
      'listen_port'    => $listen_port,
      'models_dir'     => $models_dir,
      'listen_origins' => $listen_origins,
    }),
    require => Package['ollama'],
    notify  => Service['com.ollama.serve'],
  }

  service { 'com.ollama.serve':
    ensure   => $service_ensure,
    enable   => $service_enable,
    provider => 'launchd',
    require  => File[$plist_path],
  }
}
