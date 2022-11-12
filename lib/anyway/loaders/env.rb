# frozen_string_literal: true

module Anyway
  using RubyNext

  module Loaders
    class Env < Base
      def call(env_prefix:, **_options)
        env = ::Anyway::Env.new(type_cast: ::Anyway::NoCast)

        env.fetch(env_prefix, include_trace: true).then do |result|
          Tracing.current_trace&.merge!(result.trace)
          result.data
        end
      end
    end
  end
end
