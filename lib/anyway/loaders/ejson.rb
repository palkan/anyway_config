# frozen_string_literal: true

# require "pathname"
# require "anyway/ext/hash"
require "anyway/ejson_parser"

# using RubyNext
# using Anyway::Ext::Hash

module Anyway
  module Loaders
    class EJSON < Base
      def call(name:, ejson_parser: Anyway::EJSONParser.new, **_options)
        secrets_hash = config_pathes_chain.lazy.map { |config_path| ejson_parser.call(config_path) }.find &:itself

        return {} unless secrets_hash

        config_hash = secrets_hash[name]

        return {} unless config_hash.is_a?(Hash)

        # TODO: refactor
        config_hash.transform_keys { |key| (key[0] == "_") ? key[1..] : key }
      end

      private

      def config_pathes_chain
        if use_local?
          [config_path("secrets.local.ejson")]
        elsif Settings.current_environment
          [
            config_path("#{Settings.current_environment}/secrets.ejson"),
            config_path("secrets.ejson")
          ]
        else
          [
            config_path("secrets.ejson")
          ]
        end
      end

      def config_path(config_relative_path)
        "#{Settings.app_root}/config/#{config_relative_path}"
      end
    end
  end
end
