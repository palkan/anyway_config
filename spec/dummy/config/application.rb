# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "anyway_config"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.split(".").take(2).join(".").to_f
    config.logger = Logger.new("/dev/null")
    config.eager_load = ENV["DO_NOT_INITIALIZE_RAILS"] != "1"

    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym "API"
    end

    config.autoloader = :zeitwerk if defined?(::Zeitwerk)

    config.anyway_config.use_local_files = false
    if ENV["USE_APP_CONFIGS"] == "1"
      config.anyway_config.autoload_static_config_path = "app/configs"
    end

    config.heroku = HerokuConfig.instance

    # Rails 5.2+: generate encrypted credentials from plain yml
    if Rails.application.respond_to?(:credentials)
      require "tmpdir"

      # Rails 6 support per-env credentials...
      Rails.application.encrypted(
        File.join(__dir__, "credentials/test.yml.enc"),
        key_path: File.join(__dir__, "credentials/test.key")
      ).change do |tmp_path|
        FileUtils.cp File.join(__dir__, "credentials/test.yml"), tmp_path
      end

      # ...but Rails 5.2 doesn't
      FileUtils.cp(
        File.join(__dir__, "credentials/test.yml.enc"), File.join(__dir__, "credentials.yml.enc")
      )
      FileUtils.cp(
        File.join(__dir__, "credentials/test.key"), File.join(__dir__, "master.key")
      )

      Rails.application.encrypted(
        File.join(__dir__, "credentials/local.yml.enc"),
        key_path: File.join(__dir__, "credentials/local.key")
      ).change do |tmp_path|
        FileUtils.cp File.join(__dir__, "credentials/local.yml"), tmp_path
      end
    end
  end
end
