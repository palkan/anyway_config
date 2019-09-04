# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anyway/version"

Gem::Specification.new do |s|
  s.name        = "anyway_config"
  s.version     = Anyway::VERSION
  s.authors     = ["Vladimir Dementyev"]
  s.email       = ["dementiev.vm@gmail.com"]
  s.homepage    = "http://github.com/palkan/anyway_config"
  s.summary     = "Configuration DSL for Ruby libraries and applications"
  s.description = %{
    Configuration DSL for Ruby libraries and applications.
    Allows you to easily follow the twelve-factor application principles (https://12factor.net/config).
  }

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/anyway_config/issues",
    "changelog_uri" => "https://github.com/palkan/anyway_config/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/anyway_config",
    "homepage_uri" => "http://github.com/palkan/anyway_config",
    "source_code_uri" => "http://github.com/palkan/anyway_config"
  }

  s.license = "MIT"

  s.files = `git ls-files README.md LICENSE.txt lib bin`.split
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.5"

  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "rspec", "~> 3.8"
  s.add_development_dependency "rubocop", "~> 0.63.0"
  s.add_development_dependency "rubocop-md", "~> 0.2"
  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency "standard", "~> 0.1.3"
end
