require 'r10k/puppetfile'
require 'yaml'

# Load Puppetfile
puppetfile = R10k::Puppetfile.new('.')
puppetfile.load

# Define the base structure
fixtures = {
  'fixtures' => {
    'symlinks' => {
      'bootstrap' => '#{source_dir}/site-modules/bootstrap',
      'profile'   => '#{source_dir}/site-modules/profile',
      'role'      => '#{source_dir}/site-modules/role'
    },
    'repositories' => {},
    'forge_modules' => {}
  }
}

puppetfile.modules.each do |mod|
  case mod.class.to_s
  when 'R10K::Module::Git'
    # Handles Git (GitHub/GitLab/etc)
    fixtures['fixtures']['repositories'][mod.name] = {
      'repo' => mod.instance_variable_get(:@remote),
      'ref'  => mod.instance_variable_get(:@ref) || 'master'
    }
  when 'R10K::Module::Forge'
    # Handles Puppet Forge
    fixtures['fixtures']['forge_modules'][mod.name] = {
      'repo' => mod.title,
      'ref'  => mod.version
    }
  end
end

File.open('.fixtures.yml', 'w') { |f| f.write(fixtures.to_yaml) }
puts "Successfully generated .fixtures.yml from Puppetfile"

