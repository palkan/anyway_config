# frozen_string_literal: true

module Anyway
  module Ext
    # Extend Hash through refinements
    module Hash
      refine ::Hash do
        def stringify_keys!
          keys.each do |key|
            value = delete(key)
            value.stringify_keys! if value.is_a?(::Hash)
            self[key.to_s] = value
          end

          self
        end

        def bury(val, *path)
          raise ArgumentError, "No path specified" if path.empty?
          raise ArgumentError, "Path cannot contain nil" if path.compact.size != path.size

          last_key = path.pop
          hash = path.reduce(self) do |hash, k|
            hash[k] = {} unless hash.key?(k)
            hash[k]
          end
          hash[last_key] = val
        end

        def deep_transform_keys(&block)
          each_with_object({}) do |(key, value), result|
            result[yield(key)] = value.is_a?(::Hash) ? value.deep_transform_keys(&block) : value
          end
        end
      end

      using self
    end
  end
end
