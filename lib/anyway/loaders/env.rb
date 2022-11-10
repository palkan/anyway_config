# frozen_string_literal: true

module Anyway
  using RubyNext

  module Loaders
    class Env < Base
      def call(env_prefix:, **_options)
        env = ::Anyway::Env.new(type_cast: ::Anyway::NoCast)

        env.fetch(env_prefix, include_trace: true).then do |(conf, trace)|
          Tracing.current_trace&.merge!(trace)
          conf
        end
      end
    end
  end
end
