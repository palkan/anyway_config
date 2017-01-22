module Anyway
  module Ext
    # Extend Object through refinements
    module DeepDup
      refine ::Hash do
        # Based on ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_dup
        def deep_dup
          each_with_object(dup) do |(key, value), hash|
            hash[key] = value.respond_to?(:deep_dup) ? value.deep_dup : value
          end
        end
      end

      refine ::Array do
        # From ActiveSupport http://api.rubyonrails.org/classes/Array.html#method-i-deep_dup
        def deep_dup
          map { |el| el.respond_to?(:deep_dup) ? el.deep_dup : el }
        end
      end
    end
  end
end
