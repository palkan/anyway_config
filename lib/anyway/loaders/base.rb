# frozen_string_literal: true

module Anyway
  module Loaders
    class Base
      class << self
        def call(local: false, **opts)
          new(local: local).call(**opts)
        end
      end

      def initialize(local:)
        @local = local
      end

      def use_local?
        @local == true
      end
    end
  end
end
