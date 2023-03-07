# frozen_string_literal: true

require "ruby-next"

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

require "anyway/version"

require "anyway/ext/deep_dup"
require "anyway/ext/deep_freeze"
require "anyway/ext/hash"
require "anyway/ext/flatten_names"

require "anyway/utils/deep_merge"
require "anyway/utils/which"

require "anyway/settings"
require "anyway/tracing"
require "anyway/config"
require "anyway/auto_cast"
require "anyway/type_casting"
require "anyway/env"
require "anyway/loaders"
require "anyway/rbs"

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
  loaders.append :ejson, Loaders::EJSON if Utils.which("ejson")
  loaders.append :env, Loaders::Env

  if ENV.key?("DOPPLER_TOKEN") && ENV["ANYWAY_CONFIG_DISABLE_DOPPLER"] != "true"
    loaders.append :doppler, Loaders::Doppler
  end
end

require "anyway/rails" if defined?(::Rails::VERSION)
require "anyway/testing" if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
