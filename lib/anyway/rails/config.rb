module Anyway
  class Config
    def load_from_sources(config={}.with_indifferent_access)        
      load_from_file(config)
      load_from_secrets(config)
      load_from_env(config)
    end

    def load_from_file(config)
      config_path = Rails.root.join("config","#{@config_name}.yml")
      if File.file? config_path
        require 'yaml'
        config.deep_merge! (YAML.load_file(config_path)[Rails.env] || {})
      end
      config
    end

    def load_from_secrets(config)
      if Rails.application.respond_to?(:secrets)
        config.deep_merge! (Rails.application.secrets.send(@config_name)||{})
      end
      config
    end
  end
end