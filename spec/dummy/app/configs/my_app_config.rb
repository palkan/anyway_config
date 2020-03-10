# frozen_string_literal: true

class MyAppConfig < ApplicationConfig
  attr_config :name, :mode

  required :name, :mode
end
