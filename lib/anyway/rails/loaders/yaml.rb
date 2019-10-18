# frozen_string_literal: true

module Anyway
  module Rails
    module Loaders
      class YAML < Anyway::Loaders::YAML
        def parse_yml(*)
          super[::Rails.env]
        end
      end
    end
  end
end
