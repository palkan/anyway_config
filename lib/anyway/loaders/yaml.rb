# frozen_string_literal: true

require "pathname"
require "anyway/ext/hash"

using RubyNext
using Anyway::Ext::Hash

module Anyway
  module Loaders
    class YAML < Base
      def call(config_path:, **_options)
        base_config = trace!(:yml, path: relative_config_path(config_path).to_s) { load_base_yml(config_path) }

        return base_config unless use_local?

        local_path = local_config_path(config_path)
        local_config = trace!(:yml, path: relative_config_path(local_path).to_s) { load_local_yml(local_path) }

        base_config.deep_merge!(local_config)
      end

      private

      def parse_yml(path)
        return {} unless File.file?(path)
        require "yaml" unless defined?(::YAML)
        if defined?(ERB)
          ::YAML.load(ERB.new(File.read(path)).result) # rubocop:disable Security/YAMLLoad
        else
          ::YAML.load_file(path)
        end
      end

      alias load_base_yml parse_yml
      alias load_local_yml parse_yml

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
