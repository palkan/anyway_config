# frozen_string_literal: true

module Anyway
  class TypeCasting
    class << self
      def default
        @default ||= TypeCasting.new
      end
    end

    def initialize
      @registry = {}
    end

    def accept(name_or_object, &block)
      if !block && !name_or_object.respond_to?(:deserialize)
        raise ArgumentError, "Please, provide a type casting block or an object implementing #deserialize(val) method"
      end

      registry[name_or_object] = block || ->(val) { name_or_object.deserialize(val) }
    end

    def deserialize(raw, type_id, array: false)
      caster = registry.fetch(type_id) { raise ArgumentError, "Unknown type: #{type_id}" }

      if array
        raw.split(/\s*,\s*/).map { caster.call(_1) }
      else
        caster.call(raw)
      end
    end

    def dup
      new_obj = self.class.allocate
      new_obj.instance_variable_set(:@registry, registry.dup)
      new_obj
    end

    private

    attr_reader :registry
  end

  TypeCasting.default.tap do |obj|
    obj.accept(:string) { _1 }
    obj.accept(:integer) { _1.to_i }
    obj.accept(:float) { _1.to_f }

    obj.accept(:date) do
      Date.parse(_1)
    end

    obj.accept(:datetime) do
      DateTime.parse(_1)
    end

    obj.accept(:uri) do
      URI.parse(_1)
    end

    obj.accept(:boolean) do
      _1.match?(/\A(true|t|yes|y|1)\z/i)
    end
  end
end
