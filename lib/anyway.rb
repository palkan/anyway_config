# frozen_string_literal: true

module Anyway # :nodoc:
  require "anyway/version"

  require "anyway/config"
  require "anyway/rails/config" if defined?(::Rails::VERSION)
  require "anyway/env"

  # Use Settings name to not confuse with Config.
  #
  # Settings contain the library-wide configuration.
  class Settings
    class << self
      # Define whether to load data from
      # *.yml.local (or credentials/local.yml.enc)
      attr_accessor :use_local_files
    end

    # By default, use local files only in development (that's the purpose if the local files)
    self.use_local_files = (ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development")
  end

  class << self
    def env
      @env ||= ::Anyway::Env.new
    end
  end
end
