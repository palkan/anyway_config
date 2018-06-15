# frozen_string_literal: true

require 'anyway/ext/deep_dup'

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    using Anyway::Ext::DeepDup

    # Regexp to detect array values
    # Array value is a values that contains at least one comma
    # and doesn't start/end with quote
    ARRAY_RXP = /\A[^'"].*\s*,\s*.*[^'"]\z/

    def initialize
      @data = {}
    end

    def clear
      @data.clear
    end

    def fetch(prefix)
      @data[prefix] ||= parse_env(prefix.to_s.upcase)
      @data[prefix].deep_dup
    end

    private

    def parse_env(prefix)
      ENV.each_pair.with_object({}) do |(key, val), data|
        next unless key.start_with?(prefix)

        path = key.sub(/^#{prefix}_/, '').downcase
        set_by_path(data, path, serialize_val(val))
      end
    end

    def set_by_path(to, path, val)
      parts = path.split("__")

      to = get_hash(to, parts.shift) while parts.length > 1

      to[parts.first] = val
    end

    def get_hash(from, name)
      (from[name] ||= {})
    end

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
