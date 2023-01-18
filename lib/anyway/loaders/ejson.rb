# frozen_string_literal: true

require "anyway/ejson_parser"

# using RubyNext

module Anyway
  module Loaders
    class EJSON < Base
      def call(name:, ejson_parser: Anyway::EJSONParser.new, **_options)
        configs = []

        rel_config_paths.each do |rel_config_path|
          rel_path = "config/#{rel_config_path}"
          abs_path = "#{Settings.app_root}/#{rel_path}"

          secrets_hash = ejson_parser.call(abs_path)

          next unless secrets_hash

          config_hash = secrets_hash[name]

          next unless config_hash.is_a?(Hash)

          configs <<
            trace!(:ejson, path: rel_config_path) do
              config_hash
            end
        end

        return {} if configs.empty?

        configs.inject do |result_config, next_config|
          Utils.deep_merge!(result_config, next_config)
        end
      end

      private

      def rel_config_paths
        chain = [environmental_rel_config_path]

        chain << "secrets.local.ejson" if use_local?

        chain
      end

      def environmental_rel_config_path
        if Settings.current_environment
          "#{Settings.current_environment}/secrets.ejson"
        else
          "secrets.ejson"
        end
      end
    end
  end
end
