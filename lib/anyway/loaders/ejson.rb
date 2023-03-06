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
        # name: # config name
        # env_prefix:, # prefix for env vars if any
        # config_path:#, # path to YML config
        # local: # true|false, whether to load local configuration

        secrets_hash = ejson_parser.call(config_path)

        return {} unless secrets_hash

        config_hash = secrets_hash[name]

        return {} unless config_hash.is_a?(Hash)

        # TODO: refactor
        config_hash.transform_keys { |key| (key[0] == "_") ? key[1..] : key }

        # rel_config_path = relative_config_path(config_path).to_s
        # base_config = trace!(:yml, path: rel_config_path) do
        #   config = load_base_yml(config_path)
        #   environmental?(config) ? config_with_env(config) : config
        # end

        # return base_config unless use_local?

        # local_path = local_config_path(config_path)
        # local_config = trace!(:yml, path: relative_config_path(local_path).to_s) { load_local_yml(local_path) }
        # Utils.deep_merge!(base_config, local_config)
      end

      private

      def config_path
        "#{Settings.app_root}/config/#{config_name}"
      end

      def config_name
        if use_local?
          "secrets.local.ejson"
        else
          "secrets.ejson"
        end
      end

      # def environmental?(parsed_yml)
      #   # strange, but still possible
      #   return true if Settings.default_environmental_key? && parsed_yml.key?(Settings.default_environmental_key)
      #   # possible
      #   return true if !Settings.future.unwrap_known_environments && Settings.current_environment
      #   # for other environments
      #   return true if Settings.known_environments&.any? { parsed_yml.key?(_1) }
      #   # preferred
      #   parsed_yml.key?(Settings.current_environment)
      # end

      # def config_with_env(config)
      #   env_config = config[Settings.current_environment] || {}
      #   return env_config unless Settings.default_environmental_key?

      #   default_config = config[Settings.default_environmental_key] || {}
      #   Utils.deep_merge!(default_config, env_config)
      # end

      # def parse_yml(path)
      #   return {} unless File.file?(path)
      #   require "yaml" unless defined?(::YAML)

      #   # By default, YAML load will return `false` when the yaml document is
      #   # empty. When this occurs, we return an empty hash instead, to match
      #   # the interface when no config file is present.
      #   begin
      #     if defined?(ERB)
      #       ::YAML.load(ERB.new(File.read(path)).result, aliases: true) || {}
      #     else
      #       ::YAML.load_file(path, aliases: true) || {}
      #     end
      #   rescue ArgumentError
      #     if defined?(ERB)
      #       ::YAML.load(ERB.new(File.read(path)).result) || {}
      #     else
      #       ::YAML.load_file(path) || {}
      #     end
      #   end
      # end

      # alias_method :load_base_yml, :parse_yml
      # alias_method :load_local_yml, :parse_yml

      # def local_config_path(path)
      #   path.sub(/\.yml/, ".local.yml")
      # end

      # def relative_config_path(path)
      #   Pathname.new(path).then do |path|
      #     return path if path.relative?
      #     path.relative_path_from(Settings.app_root)
      #   end
      # end
    end
  end
end
