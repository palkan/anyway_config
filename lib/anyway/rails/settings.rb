# frozen_string_literal: true

# Try to require zeitwerk
begin
  require "zeitwerk"
  require "active_support/dependencies/zeitwerk_integration"
rescue LoadError
end

module Anyway
  class Settings
    class << self
      attr_reader :autoload_static_config_path

      if defined?(::Zeitwerk)
        attr_reader :autoloader

        def autoload_static_config_path=(val)
          raise "Cannot setup autoloader after application has been initialized" if ::Rails.application.initialized?

          return unless ::Rails.root.join(val).exist?

          autoloader&.unload

          @autoload_static_config_path = val

          # See https://github.com/rails/rails/blob/8ab4fd12f18203b83d0f252db96d10731485ff6a/railties/lib/rails/autoloaders.rb#L10
          @autoloader = Zeitwerk::Loader.new.tap do |loader|
            loader.tag = "anyway.config"
            loader.inflector = ActiveSupport::Dependencies::ZeitwerkIntegration::Inflector
            loader.push_dir(::Rails.root.join(val))
            loader.setup
          end
        end

        def cleanup_autoload_paths
          return unless autoload_static_config_path
          ActiveSupport::Dependencies.autoload_paths.delete(::Rails.root.join(autoload_static_config_path).to_s)
        end
      else
        def autoload_static_config_path=(val)
          if autoload_static_config_path
            ActiveSupport::Dependencies.autoload_paths.delete(::Rails.root.join(autoload_static_config_path).to_s)
          end

          @autoload_static_config_path = val
          ActiveSupport::Dependencies.autoload_paths << ::Rails.root.join(val)
        end

        def cleanup_autoload_paths
          :no_op
        end
      end
    end

    self.default_config_path = ->(name) { ::Rails.root.join("config", "#{name}.yml") }
  end
end
