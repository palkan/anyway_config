# frozen_string_literal: true

module Anyway # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    # Add settings to Rails config
    config.anyway_config = Anyway::Settings

    # Allow autoloading of app/configs in configuration files
    ActiveSupport::Dependencies.autoload_paths << "app/configs"
  end
end
