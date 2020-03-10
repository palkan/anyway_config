# frozen_string_literal: true

module Anyway # :nodoc:
  require "anyway/version"

  require "anyway/config"

  # Use Settings name to not confuse with Config.
  #
  # Settings contain the library-wide configuration.
  class Settings
    class << self
      # Define whether to load data from
      # *.yml.local (or credentials/local.yml.enc)
      attr_accessor :use_local_files

      # Return a path to YML config file given the config name
      attr_accessor :default_config_path
    end

    # By default, use local files only in development (that's the purpose if the local files)
    self.use_local_files = (ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development")

    # By default, consider configs are stored in the ./config folder
    self.default_config_path = ->(name) { "./config/#{name}.yml" }
  end

  class << self
    def env
      @env ||= ::Anyway::Env.new
    end
  end

  require "anyway/rails/config" if defined?(::Rails::VERSION)
  require "anyway/env"
  require "anyway/railtie" if defined?(::Rails::VERSION)
  require "anyway/testing" if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
end
