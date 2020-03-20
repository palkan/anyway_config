# frozen_string_literal: true

module Anyway
  using RubyNext

  module Rails
    module Loaders
      class Secrets < Anyway::Loaders::Base
        def call(name:, **_options)
          return {} unless ::Rails.application.respond_to?(:secrets)

          # Create a new hash cause secrets are mutable!
          config = {}

          secrets.public_send(name).then do |secrets|
            config.deep_merge!(secrets) if secrets
          end

          config
        end

        private

        def secrets
          @secrets ||= begin
            ::Rails.application.secrets.tap do |_|
              # Reset secrets state if the app hasn't been initialized
              # See https://github.com/palkan/anyway_config/issues/14
              next if ::Rails.application.initialized?
              ::Rails.application.remove_instance_variable(:@secrets)
            end
          end
        end
      end
    end
  end
end
