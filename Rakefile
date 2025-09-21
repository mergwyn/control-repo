# frozen_string_literal: true

require 'bundler'
require 'puppet_litmus/rake_tasks' if Gem.loaded_specs.key? 'puppet_litmus'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet-strings/tasks' if Gem.loaded_specs.key? 'puppet-strings'

PuppetLint.configuration.send('disable_relative')
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_140chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_autoloader_layout')
PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_single_quote_string_with_variables')
PuppetLint.configuration.send('disable_strict_indent')
PuppetLint.configuration.send('disable_parameter_documentation')
PuppetLint.configuration.send('disable_parameter_order')
PuppetLint.configuration.send('disable_parameter_types')
PuppetLint.configuration.send('disable_optional_default')
PuppetLint.configuration.send('disable_lookup_in_parameter')
PuppetLint.configuration.send('disable_params_empty_string_assignment')
PuppetLint.configuration.fail_on_warnings = false
PuppetLint.configuration.ignore_paths = [".vendor/**/*.pp", ".bundle/**/*.pp", "pkg/**/*.pp", "spec/**/*.pp", "tests/**/*.pp", "types/**/*.pp", "vendor/**/*.pp"]

require 'onceover/rake_tasks'
FastGettext.default_text_domain = 'default-text-domain'
