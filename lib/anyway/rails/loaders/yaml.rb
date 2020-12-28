# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class YAML < Anyway::Loaders::YAML
        def load_base_yml(*)
          parsed_yml = super
          return parsed_yml unless environmental?(parsed_yml)

          super[::Rails.env] || {}
        end

        private

        def environmental?(parsed_yml)
          return true unless Settings.future.unwrap_known_environments
          # likely
          return true if parsed_yml.key?(::Rails.env)
          # less likely
          ::Rails.application.config.anyway_config.known_environments.any? { parsed_yml.key?(_1) }
        end

        def relative_config_path(path)
          Pathname.new(path).relative_path_from(::Rails.root)
        end
      end
    end
  end
end
