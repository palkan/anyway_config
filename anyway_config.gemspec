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
  s.summary     = "Configuration for Ruby plugins and applications"
  s.description = "Configuration for Ruby plugins and applications"
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2'

  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency "rspec", "~> 3.5.0"
end
