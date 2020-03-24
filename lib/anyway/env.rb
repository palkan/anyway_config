# frozen_string_literal: true

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    using Anyway::Ext::DeepDup
    using Anyway::Ext::Hash

    attr_reader :data, :type_cast

    def initialize(type_cast: AutoCast)
      @type_cast = type_cast
      @data = {}
    end

    def clear
      data.clear
    end

    def fetch(prefix)
      data[prefix] ||= parse_env(prefix)
      data[prefix].deep_dup
    end

    private

    def parse_env(prefix)
      match_prefix = "#{prefix}_"
      ENV.each_pair.with_object({}) do |(key, val), data|
        next unless key.start_with?(match_prefix)

        path = key.sub(/^#{prefix}_/, "").downcase

        data.bury(type_cast.call(val), *path.split("__"))
      end
    end
  end
end
