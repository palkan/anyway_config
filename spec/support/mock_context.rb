# frozen_string_literal: true

require "set"

# Special type of shared context for mocks.
# The main difference is that it can track mocked classes and methods
# and collect the corresponding real-objects calls.
# (This could be used for verification).
module RSpecMockContext
  PREFIX = "mock::"

  VerificationFailed = Class.new(StandardError)

  class << self
    attr_writer :library_path

    def library_path
      @library_path ||= File.expand_path(File.join(RSpec.configuration.default_path, "fixtures", "mocks"))
    end

    def collector = @collector ||= MocksCollector.new
    def calls = @calls ||= CallsCollector.new
  end

  class MocksCollector
    using(Module.new do
      refine RSpec::Mocks::MethodDouble do
        attr_reader :method_name
        def target_class
          @object.instance_variable_get(:@doubled_module).target
        end
      end

      refine RSpec::Mocks::InstanceMethodReference do
        attr_reader :method_name
        def target_class() = @object_reference.target
      end

      refine RSpec::Mocks::VerifyingExistingClassNewMethodDouble do
        def method_name = :initialize
        def target_class
          object
        end
      end

      refine RSpec::Mocks::VerifyingExistingMethodDouble do
        attr_reader :method_name
        def target_class() = @definition_target
      end
    end)

    VerificationPattern = Struct.new(:args_pattern, :return_type, :klass, :method_name) do
      def verified? = @verified
      def verify! = @verified = true

      def calls = @calls ||= []

      def try_verify!(call)
        args_pattern.each.with_index do |arg, i|
          next if arg == :SKIP
          # Use case-eq here to make it possible to use composed
          # matchers in the future
          return unless arg === call.arguments[i]
        end

        calls << call

        return if call.return_value.class != return_type

        verify!
      end

      def failure_message
        class_name =
          if klass.singleton_class?
            klass.inspect.sub(%r{^#<Class:}, '').sub(/>$/, '')
          else
            klass.name
          end
        "No matching call found for:\n  #{class_name}#{klass.singleton_class? ? "." : "#"}#{method_name}: (#{args_pattern.map { _1 == :SKIP ? "_" : _1.inspect }.join(', ') }) -> #{return_type}\n" \
        "Captured calls:\n#{captured_calls_message}"
      end

      def captured_calls_message
        calls.map do |call|
          args_pattern.map.with_index { |arg, i| arg == :SKIP ? "_" : call.arguments[i].inspect }.join(', ').then do |args_str|
            "  (#{args_str}) -> #{call.return_value.class}"
          end
        end.uniq.join("\n")
      end
    end

    attr_reader :mocks, :verifications

    def initialize
      @mocks = {}
      @verifications = Hash.new { |h, k| h[k] = Hash.new { |ih, ik| ih[ik] = [] } }
    end

    def watch(context_id)
      return if mocks.key?(context_id)

      tracking = mocks[context_id] = Hash.new { |h, k| h[k] = Set.new }
      evaluate_context!(context_id, tracking, verifications)
    end

    def verify!(calls_per_class)
      failure_messages = []
      calls_per_class.each do |klass, methods|
        next unless verifications.key?(klass)

        klass_verifications = verifications[klass]

        verifications[klass].each do |method_name, patterns|
          next unless methods.include?(method_name)

          methods[method_name].each do |call|
            patterns.each do |pattern|
              next if pattern.verified?

              pattern.try_verify!(call)
            end
          end

          failure_messages.concat(patterns.select { !_1.verified? }.map(&:failure_message))
        end
      end

      return true if failure_messages.empty?

      exception = VerificationFailed.new("Mocks contract verifications are missing:\n#{failure_messages.join("\n")}")
      exception.set_backtrace(caller)
      RSpec.configuration.reporter.notify_non_example_exception(exception, "An error occurred after suite run.")
      false
    end

    def mocked_methods
      @mocks.values.reduce({}, &:merge)
    end

    # Returns true for values that
    def contractable_arg?(val)
      # TODO: Support more value objects and partial matchers
      val.is_a?(::String) || val.is_a?(::Numeric)
    end

    private

    def evaluate_context!(context_id, tracking, verifications)
      this = self

      Class.new(RSpec::Core::ExampleGroup) do
        def self.metadata = {}
        def self.filtered_examples = examples

        RSpec::Core::MemoizedHelpers.define_helpers_on(self)

        include_context(context_id)

        specify("true") { expect(true).to be(true) }

        after do
          ::RSpec::Mocks.space.proxies.values.each do |proxy|
            proxy.instance_variable_get(:@method_doubles).values.each do |double|
              mid = double.method_name
              target = double.target_class

              double.stubs.each do |stub|
                next if stub.expected_args.empty?
                next unless stub.expected_args.any? { this.contractable_arg?(_1) }

                verifiable_args = stub.expected_args.map { this.contractable_arg?(_1) ? _1 : :SKIP }
                verifications[target][mid] << VerificationPattern.new(
                  verifiable_args,
                  stub.implementation.terminal_action.call.class,
                  target,
                  mid
                )
              end

              tracking[target] << mid
            end
          end
        end
      end.run
    end
  end

  class CallsCollector
    UNKNOWN = Object.new.freeze

    class CallTrace < Struct.new(:arguments, :kwargs, :return_value, :location, keyword_init: true)
      def mocked?
        location.match?(%r{/lib/rspec/mocks/}) ||
        return_value.is_a?(::RSpec::Mocks::TestDouble) ||
        (arguments || []).any? { _1.is_a?(::RSpec::Mocks::TestDouble) } ||
        (kwargs || {}).values.any? { _1.is_a?(::RSpec::Mocks::TestDouble) }
      end
    end

    attr_reader :store

    def initialize
      @store = Hash.new { |h, k| h[k] = Hash.new { |ih, ik| ih[ik] = [] } }
    end

    def start!(targets)
      store = @store
      this = self
      @tp = TracePoint.trace(:call, :return) do |tp|
        methods = targets[tp.defined_class]
        next unless methods
        next unless methods.include?(tp.method_id)

        if tp.event == :call
          method = tp.self.method(tp.method_id)
          args = []
          kwargs = {}
          method.parameters.each do |(type, name)|
            next if name == :**
            val = tp.binding.local_variable_get(name)

            case type
            when :req, :opt
              args << val
            when :keyreq, :key
              kwargs[name] = val
            when :rest
              args.concat(val)
            when :keyrest
              kwargs.merge!(val)
            end
          end

          target, mid = tp.defined_class, tp.method_id

          store[target][mid] << CallTrace.new(arguments: args, kwargs:, return_value: UNKNOWN, location: method.source_location.first)
        elsif tp.event == :return
          target, mid = tp.defined_class, tp.method_id

          call_trace = store[target][mid].last
          call_trace.return_value = tp.return_value
        end
      end
    end

    def stop
      tp.disable
      # Filter out calls involved test doubles (we only need real ones)
      @store.transform_values! do |class_calls|
        class_calls.transform_values! do |calls|
          calls.reject!(&:mocked?)
          calls
        end.tap do |method_calls|
          method_calls.delete_if { _2.empty? }
        end
      end.tap do |store|
        store.delete_if { _2.empty? }
      end
    end

    private

    attr_reader :tp
  end

  module DSL
    def mock_context(name, &block)
      RSpec.shared_context("#{PREFIX}#{name}", &block)
    end
  end

  module ExampleGroup
    def include_mock_context(name)
      context_id = "#{PREFIX}#{name}"

      RSpecMockContext.collector.watch(context_id)
      include_context(context_id)
    end
  end
end

RSpec.extend(RSpecMockContext::DSL)

if RSpec.configuration.expose_dsl_globally?
  extend(RSpecMockContext::DSL)
  Module.extend(RSpecMockContext::DSL)
end

RSpec::Core::ExampleGroup.extend(RSpecMockContext::ExampleGroup)

Dir["#{RSpecMockContext.library_path}/**/*.rb"].sort.each { |f| require f }
