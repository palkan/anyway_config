# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in anyway_config.gemspec
gem 'sqlite3'
gemspec

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'rails', '~> 5.0'
end
