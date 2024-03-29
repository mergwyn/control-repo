require 'spec_helper'

describe 'role::k8s_server' do
  on_supported_os.each do |os, os_facts|
    next unless os_facts[:osfamily] == 'Debian'

    context "on #{os}" do
      # add these two lines in a single test block to enable puppet and hiera debug mode
      # Puppet::Util::Log.level = :debug
      # Puppet::Util::Log.newdestination(:console)

      let(:facts) { os_facts }
      let(:trusted_facts) { { 'pp_role' => 'k8s_server' } }
      let(:node) { 'unittest.theclarkhome.com' }

      # Comment out to display all available resources easily
      # it { pp catalogue.resources }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
