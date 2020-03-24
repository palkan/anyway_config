# frozen_string_literal: true

module Anyway # :nodoc:
  DEFAULT_CONFIGS_PATH = "config/configs"

  class Railtie < ::Rails::Railtie # :nodoc:
    # Add settings to Rails config
    config.anyway_config = Anyway::Settings

    ActiveSupport.on_load(:before_configuration) do
      config.anyway_config.autoload_static_config_path = DEFAULT_CONFIGS_PATH
    end

    # Remove `autoload_static_config_path` from Rails `autoload_paths`
    # since we use our own autoloading mechanism
    initializer "anyway_config.cleanup_autoload" do
      Anyway::Settings.cleanup_autoload_paths
    end

    # Make sure loaders are not changed in runtime
    config.after_initialize { Anyway.loaders.freeze }
  end
end
