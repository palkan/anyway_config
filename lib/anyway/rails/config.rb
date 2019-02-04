# frozen_string_literal: true

module Anyway
  module Rails
    # Enhance config to be more Railsy-like:
    # – accept hashes with indeferent access
    # - load data from secrets
    # - recognize Rails env when loading from YML
    module Config
      module ClassMethods
        # Make defaults to be a Hash with indifferent access
        def defaults
          return @defaults if instance_variable_defined?(:@defaults)

          @defaults = super.with_indifferent_access
        end
      end

      def load_from_sources(config = {})
        config = config.with_indifferent_access
        load_from_file(config)
        load_from_secrets(config)
        load_from_env(config)
      end

      def load_from_file(config)
        config_path = ::Rails.root.join("config", "#{config_name}.yml")
        config.deep_merge!(parse_yml(config_path)[::Rails.env] || {}) if File.file? config_path
        config
      end

      def load_from_secrets(config)
        if ::Rails.application.respond_to?(:secrets)
          config.deep_merge!(::Rails.application.secrets.public_send(config_name) || {})
        end
        config
      end
    end
  end
end

Anyway::Config.prepend Anyway::Rails::Config
Anyway::Config.singleton_class.prepend Anyway::Rails::Config::ClassMethods
