# frozen_string_literal: true

require "rbs"
require "rbs/test"

module TypedVerifyingProxy
  module RBSHelper
    class << self
      def typecheck!(klass, method_name, singleton:, arguments: [], value: nil)
        method_name = method_name.to_sym

        method_call = RBS::Test::ArgumentsReturn.return(arguments:, value:)
        call_trace = RBS::Test::CallTrace.new(
          method_name:,
          method_call:,
          block_calls: [],
          block_given: block_given?
        )

        method_type = type_for(klass, method_name, singleton:)
        return unless method_type

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
        loader.add(path: Pathname("sig"))
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
