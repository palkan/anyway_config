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
        def serialize
          case self
          when ARRAY_RXP
            split(/\s*,\s*/).map { |word| word.serialize }
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
            gsub(/(\A['"]|['"]\z)/, "")
          else
            self
          end
        end
      end

      using self
    end
  end
end
