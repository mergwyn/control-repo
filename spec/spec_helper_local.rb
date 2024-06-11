# require 'rspec/mocks'
require 'rspec-puppet-utils'
def puppetdb_query(_return_vaue)
  #  Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |_args|
  #    return[{ 'key' => 'fqdn', 'value' => 'certname.example.com' }]
  #  end
  MockFunction.new('puppetdb_query') do |f|
    f.stubs(:call).with([['from', 'resources',
                          ['and', ['=', 'type', 'Zabbix_template_host'], ['=', ['parameter', 'ensure'], 'present'], ['~', 'title', '.*@unittest.theclarkhome.com']]]]).returns([{ 'title' => 'fqdn',
'value' => 'certname.example.com' }])
  end
end
#        let!(:puppetdb_query) do
#          MockFunction.new('puppetdb_query') do |f|
#            # Everything that runs puppetdb_query should be able to deal
#            # with empty results.
#            f.stubbed.returns([])
#          end

# $LOAD_PATH.push(File.join(fixture_path, 'modules', 'puppetdb','puppet', 'lib'))
# $LOAD_PATH.push(File.join(fixture_path, 'modules', 'puppetdbquery','lib'))

RSpec.configure do |config|
  config.trusted_server_facts = true
  config.before(:each) do
    # @before_each = Puppet::Parser::Functions.newfunction(:puppetdb_query, :type => :rvalue) { |args| [ [{ 'title': 'fqdn' }] ] }
    @before_each = puppetdb_query('query string')
    # @before_each = "function puppetdb_query($string) { return [{ 'title': 'fqdn' }] }"
  end
end
