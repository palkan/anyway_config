# frozen_string_literal: true

require "anyway/ejson_parser"

# using RubyNext

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
        config_relative_pathes_chain.map do |config_relative_path|
          "#{Settings.app_root}/config/#{config_relative_path}"
        end
      end

      def config_relative_pathes_chain
        chain = []

        chain << "secrets.local.ejson" if use_local?
        chain << "#{Settings.current_environment}/secrets.ejson" if Settings.current_environment
        chain << "secrets.ejson"

        chain
      end
    end
  end
end
