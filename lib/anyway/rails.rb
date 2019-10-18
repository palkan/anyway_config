# frozen_string_literal: true

module Anyway
  module Rails
  end
end

Anyway::Settings.default_config_path = ->(name) { ::Rails.root.join("config", "#{name}.yml") }

require "anyway/rails/config"
require "anyway/rails/loaders"
require "anyway/railtie"

# Configure Rails loaders
Anyway.loaders.override :yml, Anyway::Rails::Loaders::YAML
Anyway.loaders.insert_after :yml, :secrets, Anyway::Rails::Loaders::Secrets
Anyway.loaders.insert_after :secrets, :credentials, Anyway::Rails::Loaders::Credentials
