require 'spec_helper'

describe 'profile::base' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      describe 'Testing the dependencies between the classes' do
        it { is_expected.to contain_class('profile::base::users') }
        it { is_expected.to contain_class('profile::base::files') }
        it { is_expected.to contain_class('profile::base::packages') }
      end

    end
  end
end
