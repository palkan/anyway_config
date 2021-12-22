# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class YAML < Anyway::Loaders::YAML
        private

        def environmental?(parsed_yml)
          return true unless Settings.future.unwrap_known_environments
          # less likely
          return true if ::Rails.application.config.anyway_config.known_environments.any? { parsed_yml.key?(_1) }

          super parsed_yml
        end

        def relative_config_path(path)
          Pathname.new(path).relative_path_from(::Rails.root)
        end
      end
    end
  end
end
