module Anyway
  module Ext
    # Extend Object through refinements
    module Object
      refine ::Object do
        def deep_dup
          return deep_dup_hash if is_a?(::Hash)
          return deep_dup_array if is_a?(::Array)
          self
        end

        private

        # From ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_dup
        def deep_dup_hash
          each_with_object(dup) do |(key, value), hash|
            hash[key] = value.deep_dup
          end
        end

        # From ActiveSupport http://api.rubyonrails.org/classes/Array.html#method-i-deep_dup
        # NOTE: cannot use short syntax here (map(&:deep_dup)), 'cause it doesn't work with refinements
        def deep_dup_array
          map { |el| el.deep_dup }
        end
      end
    end
  end
end
