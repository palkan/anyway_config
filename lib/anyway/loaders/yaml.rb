# frozen_string_literal: true

require "anyway/ext/hash"

using RubyNext
using Anyway::Ext::Hash

module Anyway
  module Loaders
    class YAML < Base
      def call(config_path:, **_options)
        load_yml(config_path).tap do |config|
          config.deep_merge!(load_yml(local_config_path(config_path))) if use_local?
        end
      end

      private

      def load_yml(path)
        trace_hash(:yml, path: relative_config_path(path).to_s) { parse_yml(path) }
      end

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

      def relative_config_path(path)
        Pathname.new(path).then do |path|
          return path if path.relative?
          path.relative_path_from(Pathname.new(Dir.pwd))
        end
      end
    end
  end
end
