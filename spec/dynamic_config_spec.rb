# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config do
  it "loads data by config name", :aggregate_failures do
    ENV["MY_APP_TEST"] = "1"
    ENV["MY_APP_NAME"] = "my_app"

    data = Anyway::Config.for(:my_app)
    expect(data[:test]).to eq 1
    expect(data[:name]).to eq "my_app"
    expect(data[:secret]).to eq "my_secret" if Rails.application.respond_to?(:secrets)
  end
end
