# frozen_string_literal: true

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    class Parsed < Struct.new(:data, :trace)
    end

    using RubyNext
    using Anyway::Ext::DeepDup
    using Anyway::Ext::Hash

    include Tracing

    attr_reader :data, :traces, :type_cast

    def initialize(type_cast: AutoCast)
      @type_cast = type_cast
      @data = {}
      @traces = {}
    end

    def clear
      data.clear
      traces.clear
    end

    def fetch(prefix, include_trace: false)
      return if prefix.nil? || prefix.empty?

      fetch!(prefix)

      Parsed.new(data[prefix].deep_dup, include_trace ? traces[prefix] : nil)
    end

    private

    def fetch!(prefix)
      return if data.key?(prefix)

      Tracing.capture do
        data[prefix] = parse_env(prefix)
      end.then do |trace|
        traces[prefix] = trace
      end
    end

    def parse_env(prefix)
      match_prefix = "#{prefix}_"
      ENV.each_pair.with_object({}) do |(key, val), data|
        next unless key.start_with?(match_prefix)

        path = key.sub(/^#{prefix}_/, "").downcase

        paths = path.split("__")
        trace!(:env, *paths, key:) { data.bury(type_cast.call(val), *paths) }
      end
    end
  end
end
