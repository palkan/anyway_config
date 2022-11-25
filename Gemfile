# frozen_string_literal: true

source 'https://rubygems.org'

gem 'pry-byebug', platform: :mri
gem 'coveralls_reborn'
gem 'mock-suey', '~> 0.1'
gemspec

eval_gemfile "gemfiles/rubocop.gemfile"
eval_gemfile "gemfiles/rbs.gemfile"

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem 'rails', '~> 6.0'
end
