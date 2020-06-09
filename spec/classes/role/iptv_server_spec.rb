require 'spec_helper'

describe 'role::iptv_server' do
  on_supported_os.each do |os, os_facts|
    next unless os_facts[:osfamily] == 'Debian'
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
