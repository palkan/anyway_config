# frozen_string_literal: true

module Anyway
  module AutoCast
    # Regexp to detect array values
    # Array value is a values that contains at least one comma
    # and doesn't start/end with quote
    ARRAY_RXP = /\A[^'"].*\s*,\s*.*[^'"]\z/

    def self.call(val)
      return val unless String === val

      case val
      when ARRAY_RXP
        val.split(/\s*,\s*/).map { call(_1) }
      when /\A(true|t|yes|y)\z/i
        true
      when /\A(false|f|no|n)\z/i
        false
      when /\A(nil|null)\z/i
        nil
      when /\A\d+\z/
        val.to_i
      when /\A\d*\.\d+\z/
        val.to_f
      when /\A['"].*['"]\z/
        val.gsub(/(\A['"]|['"]\z)/, "")
      else
        val
      end
    end
  end
end
