# frozen_string_literal: true

require 'anyway/ext/jruby' if defined? JRUBY_VERSION
require 'anyway/ext/deep_dup'
require 'anyway/ext/deep_freeze'
require 'anyway/ext/hash'
require 'anyway/ext/string_serialize'
require 'anyway/option_parser_builder'

module Anyway # :nodoc:
  if defined? JRUBY_VERSION
    using Anyway::Ext::JRuby
  else
    using Anyway::Ext::DeepDup
    using Anyway::Ext::DeepFreeze
    using Anyway::Ext::Hash
  end
  using Anyway::Ext::StringSerialize

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
        args.each do |name|
          option_parser_descriptors[name.to_s][:ignore] = true
        end
      end

      def describe_options(**hargs)
        hargs.each do |name, desc|
          option_parser_descriptors[name.to_s][:desc] = desc
        end
      end

      def flag_options(*args)
        args.each do |name|
          option_parser_descriptors[name.to_s][:flag] = true
        end
      end

      def extend_options(&block)
        @option_parser_extension = block
      end

      def option_parser_options
        config_attributes.each_with_object({}) do |key, result|
          descriptor = option_parser_descriptors[key.to_s]
          next if descriptor[:ignore] == true

          result[key] = descriptor
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

      def option_parser_descriptors
        @option_parser_descriptors ||= Hash.new { |h, k| h[k] = {} }
      end

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
    def initialize(name: nil, load: true, overrides: {})
      @config_name = name || self.class.config_name

      raise ArgumentError, "Config name is missing" unless @config_name

      @env_prefix = self.class.env_prefix || @config_name

      self.load(overrides) if load
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
      config.deep_merge!(parse_yml(config_path) || {}) if config_path && File.file?(config_path)
      config
    end

    def load_from_env(config)
      config.deep_merge!(env_part)
      config
    end

    def option_parser
      @option_parser ||= begin
        parser = OptionParserBuilder.call(self.class.option_parser_options) do |key, arg|
          set_value(key, arg.is_a?(String) ? arg.serialize : arg)
        end
        self.class.option_parser_extension&.call(parser, self) || parser
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

    def env_part
      Anyway.env.fetch(env_prefix)
    end

    def config_path
      env_part.delete('conf') || default_config_path
    end

    def default_config_path
      "./config/#{config_name}.yml"
    end

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
