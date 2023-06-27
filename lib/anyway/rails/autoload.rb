# frozen_string_literal: true

# This module is used to detect a Rails application and activate the corresponding plugins
# when Anyway Config is loaded before Rails (e.g., in config/puma.rb).
module Anyway
  module Rails
    class << self
      attr_reader :tracer
      attr_accessor :disable_postponed_load_warning

      private

      def tracepoint_class_callback(event)
        # Ignore singletons
        return if event.self.singleton_class?

        # We wait till `rails` has been loaded, which is enough to add a railtie
        # https://github.com/rails/rails/blob/main/railties/lib/rails.rb
        return unless event.self.name == "Rails"

        # We must check for methods defined in `rails.rb` to distinguish events
        # happening when we open the `Rails` module in other files.
        if defined?(::Rails.env)
          tracer.disable

          unless disable_postponed_load_warning
            warn "Anyway Config was loaded before Rails. Activating Anyway Config Rails plugins now.\n" \
                 "NOTE: Already loaded configs were provisioned without Rails-specific sources."
          end

          require "anyway/rails"
        end
      end
    end

    @tracer = TracePoint.new(:class, &method(:tracepoint_class_callback))
    @tracer.enable
  end
end
