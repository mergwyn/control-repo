require_relative '../scripts/generate-fixtures.rb'

   desc 'Regenerate .fixtures.yml from the Puppetfile'
   task :fixtures do
     refresh_fixtures
   end

# Hook into puppetlabs_spec_helper's spec_prep lifecycle
Rake::Task[:spec_prep].enhance([:fixtures])
