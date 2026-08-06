require 'spec_helper'

describe 'role::mac_laptop' do
  on_supported_os.each do |os, os_facts|
    next unless os_facts[:osfamily] == 'Darwin'

    context "on #{os}" do
      # add these two lines in a single test block to enable puppet and hiera debug mode
      # Puppet::Util::Log.level = :debug
      # Puppet::Util::Log.newdestination(:console)
      # it { pp facts }  # uncomment to dump the facts loaded

      let(:facts) do
        os_facts.merge(
          # Standard macOS path for Homebrew on Apple Silicon or Intel
          homebrew_bin: '/usr/local/bin/brew',
        )
      end
      let(:trusted_facts) { { 'pp_role' => 'mac_laptop' } }
      let(:node) { 'unittest.theclarkhome.com' }
      let(:pre_condition) do
        'function puppetdb_query($string) { return [{ title => "fqdn", value => "certname.example.com" }] }'
      end

      # Comment out to display all available resources easily
      # it { pp catalogue.resources }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
