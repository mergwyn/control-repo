require 'yaml'

# A minimalist DSL parser to read Puppetfile without r10k overhead/errors
class PuppetfileParser
  attr_reader :modules

  def initialize
    @modules = { 'repositories' => {}, 'forge_modules' => {} }
  end

  def mod(name, args = nil)
    # Extract short name (e.g., 'stdlib')
    short_name = name.split(%r{[-/]}).last

    if args.is_a?(Hash) && args[:git]
      @modules['repositories'][short_name] = {
        'repo' => args[:git],
        'ref'  => args[:ref] || args[:tag] || args[:branch] || 'master'
      }
    else
      # Treat as Forge module
      @modules['forge_modules'][short_name] = {
        'repo' => name,
        'ref'  => args.is_a?(String) ? args : 'latest'
      }
    end
  end

  # Ignore other Puppetfile commands
  def forge(url); end
  def ruby(version); end
end

def refresh_fixtures
  puts "==> Starting Fixture Generation (DSL Mode)"
  
  unless File.exist?('Puppetfile')
    puts "  [SKIP] No Puppetfile found"
    return
  end

  begin
    parser = PuppetfileParser.new
    # Evaluate the Puppetfile content within our parser context
    parser.instance_eval(File.read('Puppetfile'))
    
    fixtures = {
      'fixtures' => {
        'symlinks' => {
          'bootstrap' => '#{source_dir}/site-modules/bootstrap',
          'profile'   => '#{source_dir}/site-modules/profile',
          'role'      => '#{source_dir}/site-modules/role'
        },
        'repositories'  => parser.modules['repositories'],
        'forge_modules' => parser.modules['forge_modules']
      }
    }

    count = parser.modules['repositories'].size + parser.modules['forge_modules'].size
    puts "  [INFO] Found #{count} modules"

    File.open('.fixtures.yml', 'w') { |f| f.write(fixtures.to_yaml) }
    puts "==> Successfully refreshed .fixtures.yml"
  rescue StandardError => e
    puts "  [ERROR] Failed to parse Puppetfile: #{e.message}"
  end
end

refresh_fixtures

