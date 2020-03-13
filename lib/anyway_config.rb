# frozen_string_literal: true

require "anyway/version"
require "anyway/settings"
require "anyway/config"
require "anyway/auto_cast"
require "anyway/env"
require "anyway/loaders"

module Anyway # :nodoc:
  class << self
    def env
      @env ||= ::Anyway::Env.new
    end

    def loaders
      @loaders ||= ::Anyway::Loaders::Registry.new
    end
  end

  # Configure default loaders
  loaders.append :yml, Loaders::YAML
  loaders.append :env, Loaders::Env
end

require "anyway/rails" if defined?(::Rails::VERSION)
require "anyway/testing" if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
