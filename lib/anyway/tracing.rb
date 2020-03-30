# frozen_string_literal: true

module Anyway
  # Provides method to trace values association
  module Tracing
    using Anyway::Ext::DeepDup

    using(Module.new do
      refine Hash do
        def inspect
          "{#{map { |k, v| "#{k}: #{v.inspect}" }.join(", ")}}"
        end
      end
    end)

    class Trace
      UNDEF = Object.new

      attr_reader :type, :value, :source

      def initialize(type = :trace, value = UNDEF, **source)
        @type = type
        @source = source
        @value = value == UNDEF ? Hash.new { |h, k| h[k] = Trace.new(:trace) } : value
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

      def keep_if(...)
        raise ArgumentError, "You can only filter :trace type, and this is :#{type}" unless trace?
        value.keep_if(...)
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

      def pretty_print(q)
        if trace?
          q.nest(2) do
            q.breakable ""
            q.seplist(value, nil, :each) do |k, v|
              q.group do
                q.text k
                q.text " =>"
                q.breakable " " unless v.trace?
                q.pp v
              end
            end
          end
        else
          q.pp value
          q.group(0, " (", ")") do
            q.seplist(source, lambda { q.breakable " " }, :each) do |k, v|
              q.group do
                q.text k.to_s
                q.text "="
                q.text v.to_s
              end
            end
          end
        end
      end
    end

    class << self
      def capture
        unless Settings.tracing_enabled
          yield
          return
        end

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
