# frozen_string_literal: true

require "anyway/ext/hash"

using Anyway::Ext::Hash

module Anyway
  module Loaders
    class YAML < Base
      def call(config_path:, **_options)
        parse_yml(config_path).tap do |config|
          config.deep_merge!(parse_yml(local_config_path(config_path))) if use_local?
        end
      end

      private

      def parse_yml(path)
        return {} unless File.file?(path)
        require "yaml" unless defined?(::YAML)
        if defined?(ERB)
          ::YAML.safe_load(ERB.new(File.read(path)).result, [], [], true)
        else
          ::YAML.load_file(path)
        end
      end

      def local_config_path(path)
        path.sub(/\.yml/, ".local.yml")
      end
    end
  end
end
