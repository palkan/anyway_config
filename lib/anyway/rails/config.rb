# frozen_string_literal: true

module Anyway
  class Config # :nodoc:
    class << self
      def defaults
        return unless @defaults

        @defaults_wia ||= @defaults.with_indifferent_access
      end
    end

    def load_from_sources(config = {})
      config = config.with_indifferent_access
      load_from_file(config)
      load_from_secrets(config)
      load_from_env(config)
    end

    def load_from_file(config)
      config.deep_merge!(parse_yml(config_path)[Rails.env] || {}) if File.file? config_path
      config
    end

    def load_from_secrets(config)
      if Rails.application.respond_to?(:secrets)
        config.deep_merge!(Rails.application.secrets.send(@config_name) || {})
      end
      config
    end

    private

    def default_config_path
      Rails.root.join("config", "#{config_name}.yml")
    end
  end
end
