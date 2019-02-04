# frozen_string_literal: true

source 'https://rubygems.org'

gem 'pry-byebug', platform: :mri

gemspec

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem 'rails', '~> 5.0'
end
