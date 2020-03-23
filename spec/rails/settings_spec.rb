# frozen_string_literal: true

require "spec_helper"

describe Anyway::Settings, :rails do
  describe "#config_autoload_paths" do
    # see spec/dummy/config/application.rb
    specify do
      expect(Rails.application.config.heroku).to be_a(HerokuConfig)
    end
  end
end
