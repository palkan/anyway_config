# frozen_string_literal: true

module Anyway
  module Ext
    # Extend Object through refinements
    module ValueSerializer
      # Regexp to detect array values
      # Array value is a values that contains at least one comma
      # and doesn't start/end with quote
      ARRAY_RXP = /\A[^'"].*\s*,\s*.*[^'"]\z/

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def serialize_val(value)
        case value
        when ARRAY_RXP
          value.split(/\s*,\s*/).map(&method(:serialize_val))
        when /\A(true|t|yes|y)\z/i
          true
        when /\A(false|f|no|n)\z/i
          false
        when /\A(nil|null)\z/i
          nil
        when /\A\d+\z/
          value.to_i
        when /\A\d*\.\d+\z/
          value.to_f
        when /\A['"].*['"]\z/
          value.gsub(/(\A['"]|['"]\z)/, '')
        else
          value
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
