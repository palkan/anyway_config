# frozen_string_literal: true

module Anyway
  # Use Settings name to not confuse with Config.
  #
  # Settings contain the library-wide configuration.
  class Settings
    class << self
      # Define whether to load data from
      # *.yml.local (or credentials/local.yml.enc)
      attr_accessor :use_local_files

      # A proc returning a path to YML config file given the config name
      attr_reader :default_config_path

      def default_config_path=(val)
        if val.is_a?(Proc)
          @default_config_path = val
          return
        end

        val = val.to_s

        @default_config_path = ->(name) { File.join(val, "#{name}.yml") }
      end

      # Enable source tracing
      attr_accessor :tracing_enabled
    end

    # By default, use local files only in development (that's the purpose if the local files)
    self.use_local_files = (ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development")

    # By default, consider configs are stored in the ./config folder
    self.default_config_path = ->(name) { "./config/#{name}.yml" }

    # Tracing is enabled by default
    self.tracing_enabled = true
  end
end
