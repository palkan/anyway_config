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

        Utils.deep_merge!(base_config, local_config)
      end

      private

      def parse_yml00(path)
        return {} unless File.file?(path)
        require "yaml" unless defined?(::YAML)

        # By default, YAML load will return `false` when the yaml document is
        # empty. When this occurs, we return an empty hash instead, to match
        # the interface when no config file is present.
        begin
          if defined?(ERB)
            ::YAML.load(ERB.new(File.read(path)).result, aliases: true) || {} # rubocop:disable Security/YAMLLoad
          else
            ::YAML.load_file(path, aliases: true) || {}
          end
        rescue ArgumentError
          if defined?(ERB)
            ::YAML.load(ERB.new(File.read(path)).result) || {} # rubocop:disable Security/YAMLLoad
          else
            ::YAML.load_file(path) || {}
          end
        end
      end

      def parse_yml(path)
        return {} unless File.file?(path)
        require "yaml" unless defined?(::YAML)

        # By default, YAML load will return `false` when the yaml document is
        # empty. When this occurs, we return an empty hash instead, to match
        # the interface when no config file is present.
        parsed_yml = if defined?(ERB)
          ::YAML.load(ERB.new(File.read(path)).result) || {} # rubocop:disable Security/YAMLLoad
        else
          ::YAML.load_file(path) || {}
        end

        return parsed_yml unless Anyway::Settings.current_environment

        env_config = parsed_yml[Anyway::Settings.current_environment] || {}
        return env_config if Anyway::Settings.default_environmental_key.blank?
        Utils.deep_merge!(default_config, env_config)
      end

      alias_method :load_base_yml, :parse_yml
      alias_method :load_local_yml, :parse_yml

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
