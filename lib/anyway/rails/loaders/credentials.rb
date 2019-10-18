# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class Credentials < Anyway::Loaders::Base
        def call(name:, **_options)
          return {} unless ::Rails.application.respond_to?(:credentials)

          # do not load from credentials if we're in the context
          # of the `credentials:edit` command
          return {} if defined?(::Rails::Command::CredentialsCommand)

          # Create a new hash cause credentials are mutable!
          config = {}

          ::Rails.application.credentials.public_send(name).yield_self do |creds|
            config.deep_merge!(creds) if creds
          end

          if use_local?
            local_credentials(name).yield_self { |creds| config.deep_merge!(creds) if creds }
          end

          config
        end

        private

        def local_credentials(name)
          local_creds_path = ::Rails.root.join("config/credentials/local.yml.enc").to_s

          return unless File.file?(local_creds_path)

          creds = ::Rails.application.encrypted(
            local_creds_path,
            key_path: ::Rails.root.join("config/credentials/local.key")
          )

          creds.public_send(name)
        end
      end
    end
  end
end
