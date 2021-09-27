# frozen_string_literal: true

class LoadConfig < Anyway::Config
  attr_config :revision
end

# Custom loader
class CustomConfigLoader < Anyway::Loaders::Base
  def call(name:, **_opts)
    trace!(:custom) do
      {revision: "ab34fg"}
    end
  end
end

Anyway.loaders.insert_after :env, :custom, CustomConfigLoader

LoadConfig.new.revision == "ab34fg" or raise "Something went wrong"
