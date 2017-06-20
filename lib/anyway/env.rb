# frozen_string_literal: true

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
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

    def fetch(config_name)
      @data[config_name] ||= parse_env(config_name)
    end

    private

    def parse_env(config_name)
      config_env_name = config_name.to_s.delete("_")
      config_env_name.upcase!
      data = {}
      ENV.each_pair do |key, val|
        if key.start_with?(config_env_name)
          _mod, path = extract_module_path(key)
          set_by_path(data, path, serialize_val(val))
        end
      end
      data
    end

    def config_key?(key)
      key =~ /^[A-Z\d]+\_[A-Z\d\_]+/
    end

    def extract_module_path(key)
      _, mod, path = key.split(/^([^\_]+)/)
      path.sub!(/^[\_]+/, '')
      [mod.downcase, path.downcase]
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
