# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class Secrets < Anyway::Loaders::Base
        def call(name:, **_options)
          return {} unless ::Rails.application.respond_to?(:secrets)

          # Create a new hash cause secrets are mutable!
          config = {}

          ::Rails.application.secrets.public_send(name).yield_self do |secrets|
            config.deep_merge!(secrets) if secrets
          end

          config
        end
      end
    end
  end
end
