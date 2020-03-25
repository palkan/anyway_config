# frozen_string_literal: true

module Anyway
  using RubyNext

  module Loaders
    class Env < Base
      def call(env_prefix:, **_options)
        Anyway.env.fetch_with_trace(env_prefix).then do |(conf, trace)|
          trace_merge!(trace)
          conf
        end
      end
    end
  end
end
