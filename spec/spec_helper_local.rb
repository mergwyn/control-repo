fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
#
RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules/site') + ':' + File.join(fixture_path, 'modules/r10k') + ':' + File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, '../../manifests')
  c.manifest = File.join(fixture_path, '../../manifests/site.pp')
  # Hiera config file for unit tests
#  c.hiera_config = File.join(fixture_path, 'hiera/hiera.yaml')
  c.fail_fast = true
end
