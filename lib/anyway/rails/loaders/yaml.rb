# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class YAML < Anyway::Loaders::YAML
        def load_base_yml(*)
          parsed_yml = super
          return parsed_yml unless environmental?(parsed_yml)

          env_config = parsed_yml[::Rails.env] || {}
          return env_config if Anyway::Settings.default_environmental_key.blank?

          default_config = parsed_yml[Anyway::Settings.default_environmental_key] || {}
          Utils.deep_merge!(default_config, env_config)
        end

        private

        def environmental?(parsed_yml)
          return true unless Settings.future.unwrap_known_environments
          # likely
          return true if parsed_yml.key?(::Rails.env)
          # less likely
          return true if ::Rails.application.config.anyway_config.known_environments.any? { parsed_yml.key?(_1) }
          # strange, but still possible
          Anyway::Settings.default_environmental_key.present? && parsed_yml.key?(Anyway::Settings.default_environmental_key)
        end

        def relative_config_path(path)
          Pathname.new(path).relative_path_from(::Rails.root)
        end
      end
    end
  end
end
