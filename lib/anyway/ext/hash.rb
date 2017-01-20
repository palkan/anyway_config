module Anyway
  module Ext
    # Extend Hash through refinements
    module Hash
      refine ::Hash do
        # From ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_merge
        def deep_merge!(other_hash)
          other_hash.each_pair do |current_key, other_value|
            this_value = self[current_key]

            if this_value.is_a?(::Hash) && other_value.is_a?(::Hash)
              this_value.deep_merge!(other_value)
              this_value
            else
              self[current_key] = other_value
            end
          end

          self
        end

        def stringify_keys!
          self.keys.each do |key|
            value = delete(key)
            value.stringify_keys! if value.is_a?(::Hash)
            self[key.to_s] = value
          end
        end
      end
    end
  end
end
