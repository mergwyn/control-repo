#!/bin/bash
ruby=/opt/puppetlabs/puppet/bin/ruby
git=/usr/bin/git
if [ -e $1/$2/.r10k-deploy.json ]
then
  ${ruby} $1/$2/scripts/code_manager_config_version.rb $1 $2
elif [ -e /opt/puppetlabs/server/pe_version ]
then
  ${ruby} $1/$2/scripts/config_version.rb $1 $2
else
  ${git} --version > /dev/null 2>&1 &&
  ${git} --git-dir $1/$2/.git rev-parse HEAD ||
  date +%s
fi
