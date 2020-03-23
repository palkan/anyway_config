# frozen_string_literal: true

module Anyway # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    # Add settings to Rails config
    config.anyway_config = Anyway::Settings

    ActiveSupport.on_load(:before_configuration) do
      config.anyway_config.autoload_static_config_path = "config/configs"
    end

    # Make sure loaders are not changed in runtime
    config.after_initialize { Anyway.loaders.freeze }
  end
end
