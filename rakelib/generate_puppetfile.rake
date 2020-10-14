require 'json'

desc 'generate puppetfile'
task :generate_puppetfile, [:mod] do |_t, args|
  args.with_defaults(mod: JSON.parse(File.read('metadata.json'))['name'])
  sh "generate-puppetfile -c  #{args.mod}"
end
