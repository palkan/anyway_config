# frozen_string_literal: true

module Anyway
  module Loaders
    class Base
      include Tracing

      class << self
        def call(local: Anyway::Settings.use_local_files, **)
          new(local:).call(**)
        end
      end

      def initialize(local: Anyway::Settings.use_local_files, **)
        @local = local
      end

      def use_local?() = @local == true

      # Whether this loader supports strict schema (so we can warn or raise on
      # unknown attributes)
      def schemaful?() = false
    end
  end
end
