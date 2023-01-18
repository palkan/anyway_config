# frozen_string_literal: true

require "anyway/ejson_parser"

module Anyway
  module Loaders
    class EJSON < Base
      def call(name:, ejson_parser: Anyway::EJSONParser.new, **_options)
        configs = []

        rel_config_paths.each do |rel_config_path|
          secrets_hash, rel_path =
            extract_hash_from_rel_config_path(
              ejson_parser: ejson_parser,
              rel_config_path: rel_config_path
            )

          next unless secrets_hash

          config_hash = secrets_hash[name]

          next unless config_hash.is_a?(Hash)

          configs <<
            trace!(:ejson, path: rel_path) do
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
          # if data from environment file is empty then take data from default one
          [
            "#{Settings.current_environment}/secrets.ejson",
            default_rel_config_path
          ]
        else
          default_rel_config_path
        end
      end

      def default_rel_config_path
        "secrets.ejson"
      end

      def extract_hash_from_rel_config_path(ejson_parser:, rel_config_path:)
        rel_config_path = [rel_config_path] unless rel_config_path.is_a?(Array)

        rel_config_path.each do |rel_conf_path|
          rel_path = "config/#{rel_conf_path}"
          abs_path = "#{Settings.app_root}/#{rel_path}"

          result = ejson_parser.call(abs_path)

          return [result, rel_path] if result
        end

        nil
      end
    end
  end
end
