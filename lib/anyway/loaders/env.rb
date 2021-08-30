# frozen_string_literal: true

module Anyway
  using RubyNext

  module Loaders
    class Env < Base
      def call(env_prefix:, type_caster: ::Anyway::AutoCast, **_options)
        env = type_caster == ::Anyway::AutoCast ? Anyway.env : ::Anyway::Env.new(type_caster:)

        env.fetch_with_trace(env_prefix).then do |(conf, trace)|
          Tracing.current_trace&.merge!(trace)
          conf
        end
      end
    end
  end
end
