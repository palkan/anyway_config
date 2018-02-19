# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in anyway_config.gemspec
gem 'sqlite3', platform: :mri

gem 'activerecord-jdbcsqlite3-adapter', '~> 50.0', platform: :jruby
gem 'jdbc-sqlite3', platform: :jruby

gem 'pry-byebug', platform: :mri

gemspec

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem 'rails', '~> 5.0'
end
