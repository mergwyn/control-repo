# spec/classes/profile/git_spec.rb
require 'spec_helper'
describe 'profile::git' do
  on_supported_os.each do |os, facts|
    next unless facts[:kernel] == 'Linux'
    context "on #{os}" do
      let (:facts) {
        facts.merge({
          :clientcert => 'build',
        })
      }
#      let(:pre_condition) { 'include profile::git' }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
