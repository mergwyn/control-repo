require 'spec_helper'

describe 'role::windows_desktop' do
  on_supported_os.each do |os, os_facts|
  next unless os_facts[:osfamily] == 'windows'
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
