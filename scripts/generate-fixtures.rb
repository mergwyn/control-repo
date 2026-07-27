#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

# A minimalist DSL parser to read Puppetfile without r10k overhead/errors
class PuppetfileParser
  attr_reader :modules

  def initialize
    @modules = { 'repositories' => {}, 'forge_modules' => {} }
  end

  def mod(name, args = nil)
    short_name = name.split(%r{[-/]}).last
    if args.is_a?(Hash) && args[:git]
      entry = {
        'repo' => args[:git],
        'ref'  => args[:ref] || args[:tag] || args[:branch] || 'master'
      }
      # If the Puppetfile declared this with :branch, also emit the 'branch' key.
      # puppetlabs_spec_helper's fixtures task uses 'branch' to do `git clone -b <branch>`
      # (which creates a local tracking branch), whereas 'ref' alone results in
      # `git reset --hard <ref>` against a repo where no local branch of that name
      # exists yet -- that's what was producing the "unknown revision" error.
      entry['branch'] = args[:branch] if args[:branch]
      @modules['repositories'][short_name] = entry
    else
      @modules['forge_modules'][short_name] = {
        'repo' => name,
        'ref'  => args.is_a?(String) ? args : 'latest'
      }
    end
  end

  # Ignore other Puppetfile commands
  def forge(_url); end
  def ruby(_version); end
end

def refresh_fixtures
  puts '==> Starting Fixture Generation (DSL Mode)'

  unless File.exist?('Puppetfile')
    puts '  [SKIP] No Puppetfile found'
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
    puts '==> Successfully refreshed .fixtures.yml'
  rescue StandardError => e
    puts "  [ERROR] Failed to parse Puppetfile: #{e.message}"
    exit 1
  end
end

# Only auto-run when executed directly (e.g. `ruby scripts/generate-fixtures.rb`
# or `scripts/generate-fixtures.rb` via shebang). When `require`d -- e.g. from a
# Rake task -- this does nothing until the caller invokes refresh_fixtures itself.
refresh_fixtures if $PROGRAM_NAME == __FILE__
