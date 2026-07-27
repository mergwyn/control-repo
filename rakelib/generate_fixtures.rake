require_relative '../scripts/generate-fixtures'

   desc 'Regenerate .fixtures.yml from the Puppetfile'
   task :fixtures do
     refresh_fixtures
   end
