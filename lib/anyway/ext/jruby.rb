# frozen_string_literal: true

module Anyway
  module Ext
    # JRuby 9.2.5.0. has a regression which breaks multiple refinements for the same
    # class, so we put them in one God-refinement
    # See https://github.com/jruby/jruby/issues/5550
    #
    # Should be fixed in 9.2.6.0
    module JRuby
      refine ::Hash do
        # Based on ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_dup
        def deep_dup
          each_with_object(dup) do |(key, value), hash|
            hash[key] = if value.is_a?(::Hash) || value.is_a?(::Array)
              value.deep_dup
            else
              value
            end
          end
        end

        def deep_freeze
          freeze
          each_value do |value|
            value.deep_freeze if value.is_a?(::Hash) || value.is_a?(::Array)
          end
        end

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
          keys.each do |key|
            value = delete(key)
            value.stringify_keys! if value.is_a?(::Hash)
            self[key.to_s] = value
          end

          self
        end
      end

      refine ::Array do
        # From ActiveSupport http://api.rubyonrails.org/classes/Array.html#method-i-deep_dup
        def deep_dup
          map do |value|
            if value.is_a?(::Hash) || value.is_a?(::Array)
              value.deep_dup
            else
              value
            end
          end
        end

        def deep_freeze
          freeze
          each do |value|
            value.deep_freeze if value.is_a?(::Hash) || value.is_a?(::Array)
          end
        end
      end

      begin
        require "active_support/core_ext/hash/indifferent_access"
      rescue LoadError
      end

      if defined?(::ActiveSupport::HashWithIndifferentAccess)
        refine ::ActiveSupport::HashWithIndifferentAccess do
          def deep_freeze
            freeze
            each_value do |value|
              value.deep_freeze if value.is_a?(::Hash) || value.is_a?(::Array)
            end
          end
        end
      end

      using self
    end
  end
end
