# frozen_string_literal: true

require "anyway/optparse_config"
require "anyway/dynamic_config"

require "anyway/ext/deep_dup"
require "anyway/ext/deep_freeze"
require "anyway/ext/hash"
require "anyway/ext/string_serialize"

module Anyway # :nodoc:
  using Anyway::Ext::DeepDup
  using Anyway::Ext::DeepFreeze
  using Anyway::Ext::Hash
  using Anyway::Ext::StringSerialize

  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    include OptparseConfig
    include DynamicConfig

    class << self
      def attr_config(*args, **hargs)
        new_defaults = hargs.deep_dup
        new_defaults.stringify_keys!

        defaults.merge! new_defaults

        new_keys = (args + new_defaults.keys) - config_attributes
        config_attributes.push(*new_keys)
        attr_accessor(*new_keys)
      end

      def defaults
        return @defaults if instance_variable_defined?(:@defaults)

        @defaults =
          if superclass < Anyway::Config
            superclass.defaults.deep_dup
          else
            {}
          end
      end

      def config_attributes
        return @config_attributes if instance_variable_defined?(:@config_attributes)

        @config_attributes =
          if superclass < Anyway::Config
            superclass.config_attributes.dup
          else
            []
          end
      end

      def config_name(val = nil)
        return (@explicit_config_name = val.to_s) unless val.nil?

        return @config_name if instance_variable_defined?(:@config_name)

        @config_name = explicit_config_name || build_config_name
      end

      def explicit_config_name
        return @explicit_config_name if instance_variable_defined?(:@explicit_config_name)

        @explicit_config_name =
          if superclass.respond_to?(:explicit_config_name)
            superclass.explicit_config_name
          end
      end

      def explicit_config_name?
        !explicit_config_name.nil?
      end

      def env_prefix(val = nil)
        return (@env_prefix = val.to_s.upcase) unless val.nil?

        return @env_prefix if instance_variable_defined?(:@env_prefix)

        @env_prefix =
          if superclass < Anyway::Config && superclass.explicit_config_name?
            superclass.env_prefix
          else
            config_name.upcase
          end
      end

      private

      def build_config_name
        unless name
          raise "Please, specify config name explicitly for anonymous class " \
            "via `config_name :my_config`"
        end

        # handle two cases:
        # - SomeModule::Config => "some_module"
        # - SomeConfig => "some"
        unless name =~ /^(\w+)(\:\:)?Config$/
          raise "Couldn't infer config name, please, specify it explicitly" \
            "via `config_name :my_config`"
        end

        Regexp.last_match[1].tap(&:downcase!)
      end
    end

    attr_reader :config_name, :env_prefix

    # Instantiate config instance.
    #
    # Example:
    #
    #   my_config = Anyway::Config.new()
    #
    #   # provide some values explicitly
    #   my_config = Anyway::Config.new({some: :value})
    #
    def initialize(overrides = {})
      @config_name = self.class.config_name

      raise ArgumentError, "Config name is missing" unless @config_name

      @env_prefix = self.class.env_prefix

      load(overrides)
    end

    def reload(overrides = {})
      clear
      load(overrides)
      self
    end

    def clear
      self.class.config_attributes.each do |attr|
        send("#{attr}=", nil)
      end
      self
    end

    def load(overrides = {})
      base_config = (self.class.defaults || {}).deep_dup

      base_config.deep_merge!(
        load_from_sources(
          name: config_name,
          env_prefix: env_prefix,
          config_path: resolve_config_path(config_name, env_prefix)
        )
      )

      base_config.merge!(overrides) unless overrides.nil?

      base_config.each do |key, val|
        set_value(key, val)
      end
    end

    def load_from_sources(**options)
      base_config = {}
      each_source(options) do |config|
        base_config.deep_merge!(config) if config
      end
      base_config
    end

    def each_source(options)
      yield load_from_file(**options)
      yield load_from_env(**options)
    end

    def load_from_file(name:, env_prefix:, config_path:, **_options)
      file_config = load_from_yml(config_path)

      if Anyway::Settings.use_local_files
        local_config_path = config_path.sub(/\.yml/, ".local.yml")
        file_config.deep_merge!(load_from_yml(local_config_path))
      end

      file_config
    end

    def load_from_env(name:, env_prefix:, **_options)
      Anyway.env.fetch(env_prefix)
    end

    def to_h
      self.class.config_attributes.each_with_object({}) do |key, obj|
        obj[key.to_sym] = send(key)
      end.deep_dup.deep_freeze
    end

    def resolve_config_path(name, env_prefix)
      Anyway.env.fetch(env_prefix).delete("conf") || default_config_path(name)
    end

    private

    def set_value(key, val)
      send("#{key}=", val) if respond_to?(key)
    end

    def load_from_yml(path)
      return {} unless File.file?(path)

      parse_yml(path)
    end

    def default_config_path(name)
      "./config/#{name}.yml"
    end

    def parse_yml(path)
      require "yaml"
      if defined?(ERB)
        YAML.safe_load(ERB.new(File.read(path)).result, [], [], true)
      else
        YAML.load_file(path)
      end
    end
  end
end
