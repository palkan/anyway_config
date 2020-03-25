# frozen_string_literal: true

module Anyway
  # Provides method to trace values association
  module Tracing
    using Anyway::Ext::DeepDup

    class Trace
      attr_reader :type, :value, :source

      def initialize(type = :trace, value = nil, **source)
        @type = type
        @source = source
        @value = value || Hash.new { |h, k| h[k] = Trace.new(:trace) }
      end

      def dig(...)
        value.dig(...)
      end

      def record_value(val, *path, key, **opts)
        trace =
          if val.is_a?(Hash)
            Trace.new.tap { _1.merge_values(val, **opts) }
          else
            Trace.new(:value, val, **opts)
          end
        target_trace = path.empty? ? self : value.dig(*path)
        target_trace.value[key.to_s] = trace

        val
      end

      def merge_values(hash, **opts)
        return hash unless hash

        hash.each do |key, val|
          if val.is_a?(Hash)
            value[key.to_s].merge_values(val, **opts)
          else
            value[key.to_s] = Trace.new(:value, val, **opts)
          end
        end

        hash
      end

      def merge!(another_trace)
        raise ArgumentError, "You can only merge into a :trace type, and this is :#{type}" unless trace?
        raise ArgumentError, "You can only merge a :trace type, but trying :#{type}" unless another_trace.trace?

        another_trace.value.each do |key, sub_trace|
          if sub_trace.trace?
            value[key].merge! sub_trace
          else
            value[key] = sub_trace
          end
        end
      end

      def clear
        value.clear
      end

      def trace?
        type == :trace
      end

      def to_h
        if trace?
          value.transform_values(&:to_h).tap { _1.default_proc = nil }
        else
          {value: value, source: source}
        end
      end
    end

    class << self
      def capture
        trace = Trace.new
        trace_stack.push trace
        yield
        trace_stack.last
      ensure
        trace_stack.pop
      end

      def trace_stack
        (Thread.current[:__anyway__trace_stack__] ||= [])
      end

      def current_trace
        trace_stack.last
      end
    end

    module_function

    def tracing?
      Tracing.current_trace
    end

    def trace_value(type, *path, **opts)
      return yield unless tracing?
      Tracing.current_trace.record_value(yield, *path, type: type, **opts)
    end

    def trace_hash(type, **opts)
      return yield unless tracing?
      Tracing.current_trace.merge_values(yield, type: type, **opts)
    end

    def trace_merge!(another_trace)
      return unless tracing?
      Tracing.current_trace.merge!(another_trace)
    end
  end
end
