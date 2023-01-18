# frozen_string_literal: true

require "anyway/ejson_parser"

module Anyway
  module Loaders
    class EJSON < Base
      def call(name:, ejson_parser: Anyway::EJSONParser.new, **_options)
        secrets_hash, relative_config_path =
          rel_config_paths.lazy.map do |rel_config_path|
            rel_path = "config/#{rel_config_path}"
            abs_path = "#{Settings.app_root}/#{rel_path}"

            [
              ejson_parser.call(abs_path),
              rel_path
            ]
          end.find { |el| el.itself[0] }

        return {} unless secrets_hash

        config_hash = secrets_hash[name]

        return {} unless config_hash.is_a?(Hash)

        trace!(:ejson, path: relative_config_path) do
          config_hash.transform_keys do |key|
            if key[0] == "_"
              key[1..]
            else
              key
            end
          end
        end
      end

      private

      def rel_config_paths
        chain = []

        chain << "secrets.local.ejson" if use_local?
        chain << "#{Settings.current_environment}/secrets.ejson" if Settings.current_environment
        chain << "secrets.ejson"

        chain
      end
    end
  end
end
