# frozen_string_literal: true

require_relative "lib/anyway/version"

Gem::Specification.new do |s|
  s.name = "anyway_config"
  s.version = Anyway::VERSION
  s.authors = ["Vladimir Dementyev"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/palkan/anyway_config"
  s.summary = "Configuration DSL for Ruby libraries and applications"
  s.description = %{
    Configuration DSL for Ruby libraries and applications.
    Allows you to easily follow the twelve-factor application principles (https://12factor.net/config).
  }

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/anyway_config/issues",
    "changelog_uri" => "https://github.com/palkan/anyway_config/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/anyway_config",
    "homepage_uri" => "http://github.com/palkan/anyway_config",
    "source_code_uri" => "http://github.com/palkan/anyway_config",
    "funding_uri" => "https://github.com/sponsors/palkan"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + Dir.glob("lib/.rbnext/**/*") +
    Dir.glob("bin/**/*") + %w[sig/anyway_config.rbs sig/manifest.yml] +
    %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.5"

  # When gem is installed from source, we add `ruby-next` as a dependency
  # to auto-transpile source files during the first load
  if ENV["RELEASING_ANYWAY"].nil? && File.directory?(File.join(__dir__, ".git"))
    s.add_runtime_dependency "ruby-next", ">= 0.14.0"
  else
    s.add_runtime_dependency "ruby-next-core", ">= 0.14.0"
  end

  s.add_development_dependency "ammeter", "~> 1.1.3"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.8"
  s.add_development_dependency "ruby-next", ">= 0.14.0"
  s.add_development_dependency "webmock", "~> 3.18"
  s.add_development_dependency "ejson", ">= 1.3.1"
end
