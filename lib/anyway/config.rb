module Anyway
  class Config
    class << self
      attr_reader :defaults, :config_attributes

      def attr_config(*args,**hargs)
        @defaults = hargs.dup.with_indifferent_access
        @config_attributes = args+hargs.keys
        attr_accessor *@config_attributes
      end

      def config_name(val = nil)
        return (@config_name = val.to_s) unless val.nil?
        @config_name ||= extract_name
      end

      private
        def extract_name
          self.name[/^(\w+)/].underscore
        end
    end

    def initialize
      load
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
      # first, copy defaults
      config = self.class.defaults.deep_dup
      config_name = self.class.config_name

      # then load from YAML if any
      config_path = Rails.root.join("config","#{config_name}.yml")
      if File.file? config_path
        config.deep_merge! (YAML.load_file(config_path)[Rails.env] || {})
      end

      # then load from Rails secrets
      unless Rails.application.try(:secrets).nil?
        config.deep_merge! (Rails.application.secrets.send(config_name)||{})
      end

      # and then load from env
      config.deep_merge! (Anyway.env.send(config_name) || {})

      config.each do |key, val| 
        self.send("#{key}=",val)
      end
    end
  end
end