# frozen_string_literal: true

module Anyway
  module Ext
    # Add #deep_freeze to hashes and arrays
    module DeepFreeze
      refine ::Hash do
        def deep_freeze
          freeze
          each_value do |value|
            value.deep_freeze if value.is_a?(::Hash) || value.is_a?(::Array)
          end
        end
      end

      refine ::Array do
        def deep_freeze
          freeze
          each do |value|
            value.deep_freeze if value.is_a?(::Hash) || value.is_a?(::Array)
          end
        end
      end
    end
  end
end
