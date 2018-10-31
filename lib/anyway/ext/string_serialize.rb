# frozen_string_literal: true

module Anyway
  module Ext
    # Extend String through refinements
    module StringSerialize
      # Regexp to detect array values
      # Array value is a values that contains at least one comma
      # and doesn't start/end with quote
      ARRAY_RXP = /\A[^'"].*\s*,\s*.*[^'"]\z/

      refine ::String do
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        def serialize
          case self
          when ARRAY_RXP
            # rubocop:disable Style/SymbolProc
            split(/\s*,\s*/).map { |word| word.serialize }
            # rubocop:enable Style/SymbolProc
          when /\A(true|t|yes|y)\z/i
            true
          when /\A(false|f|no|n)\z/i
            false
          when /\A(nil|null)\z/i
            nil
          when /\A\d+\z/
            to_i
          when /\A\d*\.\d+\z/
            to_f
          when /\A['"].*['"]\z/
            gsub(/(\A['"]|['"]\z)/, '')
          else
            self
          end
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity
      end

      using self
    end
  end
end
