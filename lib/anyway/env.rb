# frozen_string_literal: true

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    using Anyway::Ext::DeepDup
    using Anyway::Ext::StringSerialize

    def initialize
      @data = {}
    end

    def clear
      @data.clear
    end

    def fetch(prefix)
      @data[prefix] ||= parse_env(prefix)
      @data[prefix].deep_dup
    end

    private

    def parse_env(prefix)
      match_prefix = "#{prefix}_"
      ENV.each_pair.with_object({}) do |(key, val), data|
        next unless key.start_with?(match_prefix)

        path = key.sub(/^#{prefix}_/, "").downcase
        set_by_path(data, path, val.serialize)
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
