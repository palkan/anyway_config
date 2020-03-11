# frozen_string_literal: true

require "anyway/optparse_config"
require "anyway/dynamic_config"

require "anyway/ext/deep_dup"
require "anyway/ext/deep_freeze"
require "anyway/ext/hash"

module Anyway # :nodoc:
  using Anyway::Ext::DeepDup
  using Anyway::Ext::DeepFreeze
  using Anyway::Ext::Hash

  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    PARAM_NAME = /^[a-z_]([\w]+)?$/

    # List of names that couldn't be used as config names
    # (the class instance methods we use)
    RESERVED_NAMES = %i[
      config_name
      env_prefix
      values
      class
      clear
      initialize
      load
      load_from_sources
      option_parser
      raise_validation_error
      reload
      resolve_config_path
      to_h
      write_config_attr
    ].freeze

    class Error < StandardError; end
    class ValidationError < Error; end

    include OptparseConfig
    include DynamicConfig

    class << self
      def attr_config(*args, **hargs)
        new_defaults = hargs.deep_dup
        new_defaults.stringify_keys!

        defaults.merge! new_defaults

        new_keys = ((args + new_defaults.keys) - config_attributes)

        validate_param_names! new_keys.map(&:to_s)

        new_keys.map!(&:to_sym)

        unless (reserved_names = (new_keys & RESERVED_NAMES)).empty?
          raise ArgumentError, "Can not use the following reserved names as config attrubutes: " \
            "#{reserved_names.sort.map(&:to_s).join(", ")}"
        end

        config_attributes.push(*new_keys)

        define_config_accessor(*new_keys)
      end

      def defaults
        return @defaults if instance_variable_defined?(:@defaults)

        @defaults =
          if superclass < Anyway::Config
            superclass.defaults.deep_dup
          else
            new_empty_config
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

      def required(*names)
        unless (unknown_names = (names - config_attributes)).empty?
          raise ArgumentError, "Unknown config param: #{unknown_names.join(",")}"
        end

        required_attributes.push(*names)
      end

      def required_attributes
        return @required_attributes if instance_variable_defined?(:@required_attributes)

        @required_attributes =
          if superclass < Anyway::Config
            superclass.required_attributes.dup
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

      def new_empty_config
        {}
      end

      private

      def define_config_accessor(*names)
        names.each do |name|
          accessors_module.module_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{name}=(val)
              # DEPRECATED: intance variable set will be removed in 2.1
              @#{name} = values[:#{name}] = val
            end

            def #{name}
              values[:#{name}]
            end
          RUBY
        end
      end

      def accessors_module
        return @accessors_module if instance_variable_defined?(:@accessors_module)

        @accessors_module = Module.new.tap do |mod|
          include mod
        end
      end

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

      def validate_param_names!(names)
        invalid_names = names.reject { |name| name =~ PARAM_NAME }
        return if invalid_names.empty?

        raise ArgumentError, "Invalid attr_config name: #{invalid_names.join(", ")}.\n" \
          "Valid names must satisfy /#{PARAM_NAME.source}/."
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
      @values = {}

      load(overrides)
    end

    def reload(overrides = {})
      clear
      load(overrides)
      self
    end

    def clear
      values.clear
      self
    end

    def load(overrides = {})
      base_config = self.class.defaults&.deep_dup || new_empty_config

      load_from_sources(
        base_config,
        name: config_name,
        env_prefix: env_prefix,
        config_path: resolve_config_path(config_name, env_prefix)
      )

      base_config.merge!(overrides) unless overrides.nil?

      base_config.each do |key, val|
        write_config_attr(key.to_sym, val)
      end

      validate!

      self
    end

    def load_from_sources(base_config, **options)
      Anyway.loaders.each do |(_id, loader)|
        base_config.deep_merge!(loader.call(**options))
      end
      base_config
    end

    def to_h
      values.deep_dup.deep_freeze
    end

    def resolve_config_path(name, env_prefix)
      Anyway.env.fetch(env_prefix).delete("conf") || Settings.default_config_path.call(name)
    end

    # Default validation only checks for required params
    def validate!
      self.class.required_attributes.select do |name|
        values[name].nil? || (values[name].is_a?(String) && values[name].empty?)
      end.yield_self do |missing|
        next if missing.empty?
        raise_validation_error "The following config parameters are missing or empty: #{missing.join(", ")}"
      end
    end

    private

    attr_reader :values

    def write_config_attr(key, val)
      key = key.to_sym
      return unless self.class.config_attributes.include?(key)

      public_send(:"#{key}=", val)
    end

    def raise_validation_error(msg)
      raise ValidationError, msg
    end
  end
end
