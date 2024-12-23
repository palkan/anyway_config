# frozen_string_literal: true

require "pathname"

module Anyway
  # Use Settings name to not confuse with Config.
  #
  # Settings contain the library-wide configuration.
  class Settings
    # Future encapsulates settings that will be introduced in the upcoming version
    # with the default values, which could break compatibility
    class Future
      class << self
        def setting(name, default_value)
          settings[name] = default_value

          define_method(name) do
            store[name]
          end

          define_method(:"#{name}=") do |val|
            store[name] = val
          end
        end

        def settings
          @settings ||= {}
        end
      end

      def initialize
        @store = {}
      end

      def use(*names)
        store.clear
        names.each { store[_1] = self.class.settings[_1] }
      end

      setting :unwrap_known_environments, true

      private

      attr_reader :store
    end

    class << self
      # Define whether to load data from
      # *.yml.local (or credentials/local.yml.enc)
      attr_accessor :use_local_files,
        :current_environment,
        :default_environmental_key,
        :known_environments

      # Suppress required validations for CI/CD pipelines
      attr_accessor :suppress_required_validations

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

      def future
        @future ||= Future.new
      end

      def app_root
        Pathname.new(Dir.pwd)
      end

      def default_environmental_key?
        !default_environmental_key.nil?
      end

      def matching_env?(env)
        return true if env.nil? || env.to_s == current_environment

        if env.is_a?(::Hash)
          envs = env[:except]
          excluded_envs = [envs].flat_map(&:to_s)
          excluded_envs.none?(current_environment)
        elsif env.is_a?(::Array)
          env.flat_map(&:to_s).include?(current_environment)
        else
          false
        end
      end
    end

    # By default, use ANYWAY_ENV
    self.current_environment = ENV["ANYWAY_ENV"]

    # By default, use local files only in development (that's the purpose if the local files)
    self.use_local_files = (ENV["ANYWAY_ENV"] == "development" || ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development" || (defined?(Rails) && Rails.env.development?))

    # By default, consider configs are stored in the ./config folder
    self.default_config_path = ->(name) { "./config/#{name}.yml" }

    # Tracing is enabled by default
    self.tracing_enabled = true

    # By default, use ANYWAY_SUPPRESS_VALIDATIONS
    self.suppress_required_validations = %w[1 t true y yes].include?(ENV["ANYWAY_SUPPRESS_VALIDATIONS"])
  end
end
