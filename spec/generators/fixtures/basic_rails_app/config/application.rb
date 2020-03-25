# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"

# We need Ruby Next since this code is loaded in generator tests in
# a separate process
require "ruby-next/language/runtime"
RubyNext::Language.watch_dirs << File.expand_path("../../../../lib", __FILE__)

require "action_controller/railtie"
require "anyway_config"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.logger = Logger.new("/dev/null")
    config.eager_load = false
  end
end
