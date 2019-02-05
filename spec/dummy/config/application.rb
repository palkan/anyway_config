# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.logger = Logger.new("/dev/null")
    config.eager_load = false

    # Rails 6: generate encrypted credentials from plain yml
    if Rails::VERSION::MAJOR >= 6
      require "tmpdir"
      Rails.application.encrypted(
        File.join(__dir__, "credentials/test.yml.enc"),
        key_path: File.join(__dir__, "credentials/test.key")
      ).change do |tmp_path|
        FileUtils.cp File.join(__dir__, "credentials/test.yml"), tmp_path
      end
    end
  end
end
