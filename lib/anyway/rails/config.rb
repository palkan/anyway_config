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
        def new_empty_config
          {}.with_indifferent_access
        end
      end

      def each_source(options)
        yield load_from_file(**options)
        yield load_from_secrets(**options)
        yield load_from_credentials(**options)
        yield load_from_env(**options)
      end

      def load_from_file(name:, config_path:, env_prefix:, **_options)
        file_config = load_from_yml(config_path)[::Rails.env] || {}

        if Anyway::Settings.use_local_files
          local_config_path = config_path.sub(/\.yml/, ".local.yml")
          file_config.deep_merge!(load_from_yml(local_config_path) || {})
        end

        file_config
      end

      def load_from_secrets(name:, **_options)
        return unless ::Rails.application.respond_to?(:secrets)

        ::Rails.application.secrets.public_send(name)
      end

      def load_from_credentials(name:, **_options)
        # do not load from credentials if we're in the context
        # of the `credentials:edit` command
        return if defined?(::Rails::Command::CredentialsCommand)

        return unless ::Rails.application.respond_to?(:credentials)

        # Create a new hash cause credentials are mutable!
        creds_config = {}

        creds_config.deep_merge!(::Rails.application.credentials.public_send(name) || {})

        creds_config.deep_merge!(load_from_local_credentials(name: name) || {}) if Anyway::Settings.use_local_files
        creds_config
      end

      def load_from_local_credentials(name:)
        local_creds_path = ::Rails.root.join("config/credentials/local.yml.enc").to_s

        return unless File.file?(local_creds_path)

        creds = ::Rails.application.encrypted(
          local_creds_path,
          key_path: ::Rails.root.join("config/credentials/local.key")
        )

        creds.public_send(name)
      end

      def default_config_path(name)
        ::Rails.root.join("config", "#{name}.yml")
      end
    end
  end
end

Anyway::Config.prepend Anyway::Rails::Config
Anyway::Config.singleton_class.prepend Anyway::Rails::Config::ClassMethods
