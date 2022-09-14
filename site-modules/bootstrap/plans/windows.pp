# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary Bootstrap windows
# @param puppet_master The FQDN of the Puppet master you are connecting to
# @param domain_name The domain name you are using (might be irrelevant?)
# @param method The method for installing Puppet
# @param collection The specific puppet collection to use (will use version.Major if set)
# @param version The specific puppet agent version to install (if you override it should be in a format such as: 6.15.0)
# @param port The port to connect to on the master
# @param environment The Puppet environment (aka Git branch) to use
# @param certificate_extensions Any extended CSR attributes you'd like to set (pp_service,pp_role,pp_envrironment etc)
# @param startup_mode Puppet agent service startup mode
# @param wait_for_certificate How long to wait between cert checks
#
plan bootstrap::windows (
  TargetSpec                                                $targets = 'localhost',
  Stdlib::Fqdn                                              $puppet_master,
  Stdlib::Fqdn                                              $domain_name,
  Enum['Chocolatey', 'Legacy']                              $method = 'Legacy',
  Enum['6','7']                                             $collection = '7',
  Pattern[/^(\d{1,2}\.)?(\d{1,2}\.)?(\d{1,2})$/,/^latest$/] $version = 'latest',
  Stdlib::Port                                              $port = 8140,
  String                                                    $environment = 'production',
  Hash                                                      $certificate_extensions = {},
  Enum['Automatic', 'Manual', 'Disabled']                   $startup_mode = 'Automatic',
  Integer                                                   $wait_for_certificate = 30
) {
  out::message('Hello from bootstrap::windows')
  return run_script(
    'bootstrap/scripts/puppet-windows.ps1',
    $targets,
    pwsh_params => {
      'PuppetMaster'          => $puppet_master,
      'DomainName'            => $domain_name,
      'InstallationMethod'    => $method,
      'Collection'            => $collection,
      'PuppetAgentVersion'    => $version,
      'MasterPort'            => $port,
      'PuppetEnvironment'     => $environment,
      'CertificateExtensions' => $certificate_extensions,
      'StartupMode'           => $startup_mode,
      'WaitForCertificate'    => $wait_for_certificate,
    }
  )
}
