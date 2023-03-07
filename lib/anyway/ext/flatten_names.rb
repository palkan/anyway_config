# frozen_string_literal: true

module Anyway
  module Ext
    # Convert Hash with mixed array and hash values to an
    # array of paths.
    module FlattenNames
      refine ::Array do
        def flatten_names(prefix, buf)
          if empty?
            buf << :"#{prefix}"
            return buf
          end

          each_with_object(buf) do |name, acc|
            if name.is_a?(::Symbol)
              acc << :"#{prefix}.#{name}"
            else
              name.flatten_names(prefix, acc)
            end
          end
        end
      end

      refine ::Hash do
        def flatten_names(prefix = nil, buf = [])
          each_with_object(buf) do |(k, v), acc|
            parent = prefix ? "#{prefix}.#{k}" : k
            v.flatten_names(parent, acc)
          end
        end
      end

      using self
    end
  end
end
