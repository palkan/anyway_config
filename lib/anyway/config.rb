module Anyway
  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    class << self
      attr_reader :defaults, :config_attributes

      def attr_config(*args, hargs)
        @defaults = hargs.dup.with_indifferent_access
        @config_attributes = args + hargs.keys
        attr_accessor(*@config_attributes)
      end

      def config_name(val = nil)
        return (@config_name = val.to_s) unless val.nil?
        @config_name ||= extract_name
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

      private

      def extract_name
        name[/^(\w+)/].underscore
      end
    end

    def initialize(config_name = nil, do_load = true)
      @config_name = config_name || self.class.config_name
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
      config = load_from_sources self.class.defaults.deep_dup
      config.each do |key, val|
        set_value(key, val)
      end
    end

    def load_from_sources(config = {}.with_indifferent_access)
      load_from_file(config)
      load_from_env(config)
    end

    def load_from_file(config)
      config_path = (Anyway.env.send(@config_name) || {}).delete(:conf)
      if config_path && File.file?(config_path)
        require 'yaml'
        config.deep_merge!(YAML.load_file(config_path) || {})
      end
      config
    end

    def load_from_env(config)
      config.deep_merge!(Anyway.env.send(@config_name) || {})
      config
    end

    private

    # safe way to assing config value
    # checks that key exists in config
    def set_value(key, val)
      send("#{key}=", val) if self.class.config_attributes.include?(key.to_sym)
    end
  end
end
