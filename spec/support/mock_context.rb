# frozen_string_literal: true

require "set"

# Special type of shared context for mocks.
# The main difference is that it can track mocked classes and methods
# and collect the corresponding real-objects calls.
# (This could be used for verification).
module RSpecMockContext
  PREFIX = "mock::"

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

    attr_reader :mocks

    def initialize
      @mocks = {}
    end

    def watch(context_id)
      return if mocks.key?(context_id)

      tracking = mocks[context_id] = Hash.new { |h, k| h[k] = Set.new }
      evaluate_context!(context_id, tracking)
    end

    def mocked_methods
      @mocks.values.reduce({}, &:merge)
    end

    private

    def evaluate_context!(context_id, tracking)
      Class.new(RSpec::Core::ExampleGroup) do
        def self.metadata = {}
        def self.filtered_examples = examples

        RSpec::Core::MemoizedHelpers.define_helpers_on(self)

        include_context(context_id)

        specify("true") { expect(true).to be(true) }

        after do
          ::RSpec::Mocks.space.proxies.values.each do |proxy|
            proxy.instance_variable_get(:@method_doubles).values.each do |double|
              tracking[double.target_class] << double.method_name
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

          store[tp.defined_class][tp.method_id] << CallTrace.new(arguments: args, kwargs:, return_value: UNKNOWN, location: method.source_location.first)
        elsif tp.event == :return
          call_trace = store[tp.defined_class][tp.method_id].last
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
