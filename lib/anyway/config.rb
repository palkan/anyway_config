# frozen_string_literal: true

require 'anyway/ext/deep_dup'
require 'anyway/ext/deep_freeze'
require 'anyway/ext/hash'
require 'anyway/option_parser_builder'

module Anyway # :nodoc:
  using Anyway::Ext::DeepDup
  using Anyway::Ext::DeepFreeze
  using Anyway::Ext::Hash

  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    class << self
      attr_reader :defaults, :config_attributes, :option_parser_extension

      def attr_config(*args, **hargs)
        @defaults ||= {}
        @config_attributes ||= []

        new_defaults = hargs.deep_dup
        new_defaults.stringify_keys!
        defaults.merge! new_defaults

        new_keys = (args + new_defaults.keys) - config_attributes
        @config_attributes += new_keys
        attr_accessor(*new_keys)
      end

      def config_name(val = nil)
        return (@config_name = val.to_s) unless val.nil?

        @config_name = underscore_name unless defined?(@config_name)
        @config_name
      end

      def ignore_options(*args)
        @ignore_options ||= []
        @ignore_options |= args
      end

      def describe_options(**hargs)
        @option_parser_descriptions ||= {}
        @option_parser_descriptions.merge!(hargs.stringify_keys!)
      end

      def extend_options(&block)
        @option_parser_extension = block
      end

      def option_parser_options
        ignored_options = @ignore_options || []
        descriptions = @option_parser_descriptions || {}
        config_attributes.each_with_object({}) do |key, result|
          next if ignored_options.include?(key.to_sym)

          result[key] ||= descriptions[key.to_s]
        end
      end

      def env_prefix(val = nil)
        return (@env_prefix = val.to_s) unless val.nil?

        @env_prefix
      end

      # Load config as Hash by any name
      #
      # Example:
      #
      #   my_config = Anyway::Config.for(:my_app)
      #   # will load data from config/my_app.yml, secrets.my_app, ENV["MY_APP_*"]
      def for(name)
        new(name: name, load: false).load_from_sources
      end

      private

      def underscore_name
        return unless name

        word = name[/^(\w+)/]
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.downcase!
        word
      end
    end

    attr_reader :config_name, :env_prefix

    # Instantiate config with specified name, loads the data and applies overrides
    #
    # Example:
    #
    #   my_config = Anyway::Config.new(name: :my_app, load: true, overrides: { some: :value })
    #
    # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/LineLength,Metrics/CyclomaticComplexity
    def initialize(name: nil, load: true, overrides: {})
      @config_name = name || self.class.config_name

      raise ArgumentError, "Config name is missing" unless @config_name

      if @config_name.to_s.include?('_') && self.class.env_prefix.nil?
        warn "[Deprecated] As your config_name is #{@config_name}, " \
             "the prefix `#{@config_name.to_s.delete('_').upcase}` " \
             "will be used to parse env variables. " \
             "This behavior is about to change in 1.4.0 (no more deleting underscores). " \
             "Env prefix can be set explicitly with `env_prefix` method now already " \
             "(check out the docs), and it will be used as is."
      end

      @env_prefix = self.class.env_prefix || @config_name.to_s&.delete('_')

      self.load(overrides) if load
    end
    # rubocop:enable Metrics/MethodLength,Metrics/AbcSize,Metrics/LineLength,Metrics/CyclomaticComplexity

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
      config = load_from_sources((self.class.defaults || {}).deep_dup)

      config.merge!(overrides) unless overrides.nil?
      config.each do |key, val|
        set_value(key, val)
      end
    end

    def load_from_sources(config = {})
      # Handle anonymous configs
      return config unless config_name

      load_from_file(config)
      load_from_env(config)
    end

    def load_from_file(config)
      config_path = Anyway.env.fetch(env_prefix).delete('conf') ||
                    "./config/#{config_name}.yml"
      config.deep_merge!(parse_yml(config_path) || {}) if config_path && File.file?(config_path)
      config
    end

    def load_from_env(config)
      config.deep_merge!(Anyway.env.fetch(env_prefix))
      config
    end

    def option_parser
      @option_parser ||= begin
        parser = OptionParserBuilder.call(self.class.option_parser_options) do |key, arg|
          set_value(key, arg)
        end
        self.class.option_parser_extension&.call(parser) || parser
      end
    end

    def parse_options!(options)
      option_parser.parse!(options)
    end

    def to_h
      self.class.config_attributes.each_with_object({}) do |key, obj|
        obj[key.to_sym] = send(key)
      end.deep_dup.deep_freeze
    end

    private

    def set_value(key, val)
      send("#{key}=", val) if respond_to?(key)
    end

    def parse_yml(path)
      require 'yaml'
      if defined?(ERB)
        YAML.safe_load(ERB.new(File.read(path)).result, [], [], true)
      else
        YAML.load_file(path)
      end
    end
  end
end
