# frozen_string_literal: true

class HerokuConfig < ApplicationConfig
  attr_config :app_id, :app_name, :dyno_id, :release_version, :slug_commit
end
