# frozen_string_literal: true

module Anyway
  # Adds ability to generate anonymous (class-less) config dynamicly
  # (like Rails.application.config_for but using more data sources).
  module DynamicConfig
    module ClassMethods
      # Load config as Hash by any name
      #
      # Example:
      #
      #   my_config = Anyway::Config.for(:my_app)
      #   # will load data from config/my_app.yml, secrets.my_app, ENV["MY_APP_*"]
      #
      def for(name, **options)
        config = allocate
        options[:env_prefix] ||= name.to_s.upcase
        options[:config_path] ||= config.resolve_config_path(name, options[:env_prefix])
        config.load_from_sources(new_empty_config, name:, **options)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
