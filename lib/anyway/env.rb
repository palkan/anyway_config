# frozen_string_literal: true

require 'anyway/ext/value_serializer'
require 'anyway/ext/deep_dup'

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    include Anyway::Ext::ValueSerializer
    using Anyway::Ext::DeepDup

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
  end
end
