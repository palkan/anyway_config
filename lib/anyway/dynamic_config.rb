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
      # TODO: add config_path option, env_prefix option
      def for(name)
        new(name: name, load: false).load_from_sources
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
