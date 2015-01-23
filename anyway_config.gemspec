# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anyway/version'

Gem::Specification.new do |s|
  s.name        = "anyway_config"
  s.version     = Anyway::VERSION
  s.authors     = ["Vlad Dem"]
  s.email       = ["dementiev.vm@gmail.com"]
  s.homepage    = "http://github.com/palkan/anyway_config"
  s.summary     = "Configuration for Rails plugins and applications"
  s.description = "Configuration for Rails plugins and applications"
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9.3'

  s.add_development_dependency 'pry'
  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency "rspec", "~> 3.0.0"
  s.add_development_dependency "rspec-rails", "~> 3.0.0"
end
