# frozen_string_literal: true

require 'anyway/ext/class'
require 'anyway/ext/deep_dup'
require 'anyway/ext/deep_freeze'
require 'anyway/ext/hash'

module Anyway # :nodoc:
  using Anyway::Ext::Class
  using Anyway::Ext::DeepDup
  using Anyway::Ext::DeepFreeze
  using Anyway::Ext::Hash

  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    class << self
      attr_reader :defaults, :config_attributes

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

      # Load config as Hash by any name
      #
      # Example:
      #
      #   my_config = Anyway::Config.for(:my_app)
      #   # will load data from config/my_app.yml, secrets.my_app, ENV["MY_APP_*"]
      def for(name)
        new(name, false).load_from_sources
      end
    end

    attr_reader :config_name

    def initialize(config_name = nil, do_load = true)
      @config_name = config_name || self.class.config_name
      raise ArgumentError, "Config name is missing" unless @config_name
      load if do_load
    end

    def reload
      clear
      load
      self
    end

    def clear
      self.class.config_attributes.each do |attr|
        send("#{attr}=", nil)
      end
      self
    end

    def load
      config = load_from_sources((self.class.defaults || {}).deep_dup)
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
      config_path = Anyway.env.fetch(config_name).delete('conf') ||
                    "./config/#{config_name}.yml"
      if config_path && File.file?(config_path)
        config.deep_merge!(parse_yml(config_path) || {})
      end
      config
    end

    def load_from_env(config)
      config.deep_merge!(Anyway.env.fetch(config_name))
      config
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
        YAML.safe_load(ERB.new(File.read(path)).result)
      else
        YAML.load_file(path)
      end
    end
  end
end
