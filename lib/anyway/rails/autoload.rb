# frozen_string_literal: true

# This module is used to detect a Rails application and activate the corresponding plugins
# when Anyway Config is loaded before Rails (e.g., in config/puma.rb).
module Anyway
  module Rails
    using RubyNext

    class << self
      attr_reader :tracer, :name_method
      attr_accessor :disable_postponed_load_warning

      private

      def tracepoint_class_callback(event)
        # Ignore singletons
        return if event.self.singleton_class?

        # We wait till `rails/application/configuration.rb` has been loaded, since we rely on it
        # See https://github.com/palkan/anyway_config/issues/134
        return unless name_method.bind_call(event.self) == "Rails::Application::Configuration"

        tracer.disable

        unless disable_postponed_load_warning
          warn "Anyway Config was loaded before Rails. Activating Anyway Config Rails plugins now.\n" \
                "NOTE: Already loaded configs were provisioned without Rails-specific sources."
        end

        require "anyway/rails"
      end
    end

    # TruffleRuby doesn't support TracePoint's end event
    unless defined?(::TruffleRuby)
      @tracer = TracePoint.new(:end, &method(:tracepoint_class_callback))
      @tracer.enable
      # Use `Module#name` instead of `self.name` to handle overwritten `name` method
      @name_method = Module.instance_method(:name)
    end
  end
end
