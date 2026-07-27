require_relative '../scripts/generate-fixtures.rb'

   desc 'Regenerate .fixtures.yml from the Puppetfile'
   task :fixtures do
     refresh_fixtures
   end
