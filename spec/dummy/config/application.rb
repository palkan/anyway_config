# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.logger = Logger.new("/dev/null")
    config.eager_load = false
  end
end
