# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

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
        load_from_credentials(config)
        load_from_env(config)
      end

      def load_from_file(config)
        config_path = resolve_config_path
        config.deep_merge!(load_from_yml(config_path)[::Rails.env] || {})

        if Anyway::Settings.use_local_files
          local_config_path = config_path.sub(/\.yml/, ".local.yml")
          config.deep_merge!(load_from_yml(local_config_path) || {})
        end

        config
      end

      def load_from_secrets(config)
        if ::Rails.application.respond_to?(:secrets)
          config.deep_merge!(::Rails.application.secrets.public_send(config_name) || {})
        end
        config
      end

      def load_from_credentials(config)
        # do not load from credentials if we're in the context
        # of the `credentials:edit` command
        return if defined?(::Rails::Command::CredentialsCommand)

        if ::Rails.application.respond_to?(:credentials)
          config.deep_merge!(::Rails.application.credentials.public_send(config_name) || {})

          load_from_local_credentials(config) if Anyway::Settings.use_local_files
        end
        config
      end

      def load_from_local_credentials(config)
        local_creds_path = ::Rails.root.join("config/credentials/local.yml.enc").to_s

        return unless File.file?(local_creds_path)

        creds = ::Rails.application.encrypted(
          local_creds_path,
          key_path: ::Rails.root.join("config/credentials/local.key")
        )

        config.deep_merge!(creds.public_send(config_name) || {})
      end

      def default_config_path
        ::Rails.root.join("config", "#{config_name}.yml")
      end
    end
  end
end

Anyway::Config.prepend Anyway::Rails::Config
Anyway::Config.singleton_class.prepend Anyway::Rails::Config::ClassMethods
