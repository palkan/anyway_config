# frozen_string_literal: true

module Anyway
  module Loaders
    class Env < Base
      def call(env_prefix:, **_options)
        Anyway.env.fetch(env_prefix)
      end
    end
  end
end
