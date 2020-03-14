# frozen_string_literal: true

module Anyway
  module Ext
    # Extend Hash through refinements
    module Hash
      refine ::Hash do
        # From ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_merge
        def deep_merge!(other_hash)
          merge!(other_hash) do |key, this_value, other_value|
            if this_value.is_a?(::Hash) && other_value.is_a?(::Hash)
              this_value.deep_merge!(other_value)
              this_value
            else
              other_value
            end
          end
        end

        def stringify_keys!
          keys.each do |key|
            value = delete(key)
            value.stringify_keys! if value.is_a?(::Hash)
            self[key.to_s] = value
          end

          self
        end
      end

      using self
    end
  end
end
