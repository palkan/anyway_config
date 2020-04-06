# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class YAML < Anyway::Loaders::YAML
        def load_base_yml(*)
          super[::Rails.env] || {}
        end

        private

        def relative_config_path(path)
          Pathname.new(path).relative_path_from(::Rails.root)
        end
      end
    end
  end
end
