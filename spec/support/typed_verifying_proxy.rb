# frozen_string_literal: true

require "rbs"
require "rbs/test"

module TypedVerifyingProxy
  module RBSHelper
    class MissingSignature < StandardError
    end

    class SignatureGenerator
      attr_reader :klass, :method_calls, :constants, :singleton
      alias singleton? singleton

      def initialize(klass, method_calls)
        @klass = klass
        @singleton = klass.singleton_class?
        @method_calls = method_calls
        @constants = Set.new
      end

      def to_rbs
        [
          header,
          *method_calls.map { |name, calls| method_sig(name, calls) },
          footer
        ].join("\n")
      end

      private

      def class_name
        if singleton?
          klass.inspect.sub(%r{^#<Class:}, '').sub(/>$/, '')
        else
          klass.name
        end
      end

      def header
        nesting_parts = class_name.split("::")

        base = Kernel
        nesting = 0

        lines = []

        nesting_parts.map do |const|
          base = base.const_get(const)
          lines << "#{"  " * nesting}#{base.is_a?(Class) ? "class" : "module"} #{const}"
          nesting += 1
        end

        @nesting = nesting_parts.size

        lines.join("\n")
      end

      def footer
        @nesting.times.map do |n|
          "#{"  " * (@nesting - n - 1)}end"
        end.join("\n")
      end

      def method_sig(name, calls)
        "#{"  " * @nesting}def #{singleton? ? "self.": ""}#{name}: (#{[args_sig(calls.map { _1[0] }), kwargs_sig(calls.map { _1[1] })].compact.join(", ")}) -> (#{return_sig(name, calls.map { _1[2] })})"
      end

      def args_sig(args)
        return if args.all?(&:empty?)

        args.transpose.map do |arg_values|
          arg_values.map(&:class).uniq.map do
            constants << _1
            "::#{_1.name}"
          end
        end.join(", ")
      end

      def kwargs_sig(kwargs)
        return if kwargs.all?(&:empty?)

        key_values = kwargs.reduce(Hash.new { |h,k| h[k] = [] }) { |acc, pairs| pairs.each { acc[_1] << _2 }; acc }

        key_values.map do |key, values|
          values_sig = values.map(&:class).uniq.map do
            constants << _1
            "::#{_1.name}"
          end.join(" | ")

          "?#{key}: (#{values_sig})"
        end.join(", ")
      end

      def return_sig(name, values)
        # Special case
        return "void" if name == :initialize

        values.map(&:class).uniq.map do
          constants << _1
          "::#{_1.name}"
        end.join(" | ")
      end
    end

    class << self
      def generate!(calls_per_class, stub_constants: true)
        constants = Set.new

        calls_per_class.each do |klass, methods|
          next unless methods
          generator = SignatureGenerator.new(klass, methods)

          decl = generator.to_rbs.then do |rbs|
            puts "\n#{rbs}" if ENV["DEBUG_RBS"] == "true"
            RBS::Parser.parse_signature(rbs)
          end.then do |declarations|
            declarations.each do |decl|
              env << decl
            end
          end

          constants |= generator.constants
        end

        # Generate constant stubs for unknown constants
        if stub_constants
          constants.each_with_object({}) do |const, acc|
            acc[const] = {}
            acc
          end.then do |const_hash|
            generate!(const_hash, stub_constants: false)
          end
        end
      end

      def pending_calls
        @pending_calls ||= []
      end

      # Process captured calls again—we should have signatures now
      def postcheck!
        failed_examples = Set.new

        pending_calls.dup.each do |args|
          example = args.shift
          kwargs = args.pop
          typecheck!(*args, **kwargs, raise_on_missing: true)
        rescue RBS::Test::Tester::TypeError, MissingSignature => err
          example.execution_result.status = :failed
          example.set_aggregate_failures_exception(err)
          failed_examples << example
        end

        failed_examples.each do |example|
          example.execution_result.exception = example.exception
          RSpec.configuration.reporter.example_failed(example)
        end

        failed_examples.none?
      end

      def typecheck!(klass, method_name, singleton:, arguments: [], value: nil, raise_on_missing: false)
        method_name = method_name.to_sym

        method_call = RBS::Test::ArgumentsReturn.return(arguments:, value:)
        call_trace = RBS::Test::CallTrace.new(
          method_name:,
          method_call:,
          block_calls: [],
          block_given: block_given?
        )

        method_type = type_for(klass, method_name, singleton:)

        unless method_type
          pending_calls << [RSpec.current_example, klass, method_name, {singleton:, arguments:, value:}] unless method_name == :new
          raise MissingSignature, "No signature found for #{klass}#{singleton ? "." : "#"}#{method_name}" if raise_on_missing
          return
        end

        typecheck = RBS::Test::TypeCheck.new(
          self_class: klass,
          builder: builder,
          sample_size: 100,
          unchecked_classes: [],
          instance_class: klass,
          class_class: singleton ? klass : klass.singleton_class
        )

        errors = []
        typecheck.overloaded_call(
          method_type,
          "#{singleton ? "." : "#"}#{method_name}",
          call_trace,
          errors:
        )

        reject_returned_instance_doubles!(errors)

        raise RBS::Test::Tester::TypeError.new(errors) unless errors.empty?
      end

      def type_for(klass, method_name, singleton: false)
        type = type_for_class(klass)
        return unless env.class_decls[type]

        decl = singleton ? builder.build_singleton(type) : builder.build_instance(type)

        decl.methods[method_name]
      end

      def type_for_class(klass)
        *path, name = *klass.name.split("::").map(&:to_sym)

        namespace = path.empty? ? RBS::Namespace.root : RBS::Namespace.new(absolute: true, path:)

        RBS::TypeName.new(name:, namespace:)
      end

      def env
        return @env if instance_variable_defined?(:@env)

        loader = RBS::EnvironmentLoader.new
        loader.add(path: Pathname("sig")) if ENV["RBS_SIG"] == "true"
        @env = RBS::Environment.from_loader(loader).resolve_type_names
      end

      def builder() = @builder ||= RBS::DefinitionBuilder.new(env:)

      private

      def reject_returned_instance_doubles!(errors)
        errors.reject! do |error|
          case error
          in RBS::Test::Errors::ReturnTypeError[
            type:,
            value: RSpec::Mocks::InstanceVerifyingDouble => double
          ]
            double.instance_variable_get(:@doubled_module).target.to_s == type.name.to_s.gsub(/^::/, "")
          else
            false
          end
        end
      end
    end
  end

  using(Module.new do
    refine RSpec::Mocks::MethodDouble do
      attr_reader :method_name
      def target_class() = @object.class
    end

    refine RSpec::Mocks::InstanceMethodReference do
      attr_reader :method_name
      def target_class() = @object_reference.target
    end

    refine RSpec::Mocks::VerifyingExistingClassNewMethodDouble do
      attr_reader :method_name
      def target_class() = @method_stasher.instance_variable_get(:@klass)
    end

    refine RSpec::Mocks::VerifyingExistingMethodDouble do
      attr_reader :method_name
      def target_class() = @method_stasher.instance_variable_get(:@klass)
    end
  end)

  def proxy_method_invoked(obj, *args, &block)
    singleton = false
    target_class = @method_reference.target_class

    if target_class.singleton_class?
      singleton = true
      target_class = obj
    end

    mid = @method_reference.method_name

    super.tap do |ret|
      RBSHelper.typecheck!(target_class, mid, singleton:, arguments: args, value: ret)
    end
  end
end

RSpec::Mocks::VerifyingMethodDouble.prepend(TypedVerifyingProxy)
