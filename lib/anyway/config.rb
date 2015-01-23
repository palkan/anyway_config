module Anyway
  class Config
    class << self
      attr_reader :defaults, :config_attributes

      def attr_config(*args,hargs)
        @defaults = hargs.dup.with_indifferent_access
        @config_attributes = args+hargs.keys
        attr_accessor *@config_attributes
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
        self.new(name,false).load_from_sources
      end

      private
        def extract_name
          self.name[/^(\w+)/].underscore
        end
    end

    def initialize(config_name=nil, do_load=true)
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
        self.send("#{attr}=", nil)
      end
      self
    end

    def load
      config = load_from_sources self.class.defaults.deep_dup
      config.each do |key, val| 
        self.send("#{key}=",val)
      end
    end

    def load_from_sources(config={}.with_indifferent_access)        
      # then load from YAML if any
      config_path = Rails.root.join("config","#{@config_name}.yml")
      if File.file? config_path
        require 'yaml'
        config.deep_merge! (YAML.load_file(config_path)[Rails.env] || {})
      end

      # then load from Rails secrets
      unless Rails.application.try(:secrets).nil?
        config.deep_merge! (Rails.application.secrets.send(@config_name)||{})
      end

      # and then load from env
      config.deep_merge! (Anyway.env.send(@config_name) || {})
      config
    end
  end
end