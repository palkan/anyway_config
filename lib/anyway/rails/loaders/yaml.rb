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
          parsed_yml.keys.any? { |key| ["test", "development", "production", ::Rails.env].include?(key) }
        end

        def relative_config_path(path)
          Pathname.new(path).relative_path_from(::Rails.root)
        end
      end
    end
  end
end
