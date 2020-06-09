require 'spec_helper'

describe 'role::domain_controller' do
  on_supported_os.each do |os, os_facts|
    next unless os_facts[:osfamily] == 'Debian'
    context "on #{os}" do
      # add these two lines in a single test block to enable puppet and hiera debug mode
      # Puppet::Util::Log.level = :debug
      # Puppet::Util::Log.newdestination(:console)
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
