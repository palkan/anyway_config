# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config, type: :config do
  around do |ex|
    with_env(
      "MY_APP_TEST" => "1",
      "MY_APP_NAME" => "my_app",
      &ex
    )
  end

  it "loads data by config name", :aggregate_failures do
    data = Anyway::Config.for(:my_app)
    expect(data[:test]).to eq 1
    expect(data[:name]).to eq "my_app"
    expect(data[:secret]).to eq "my_secret" if Rails.application.respond_to?(:secrets)
    expect(data[:credo]).to eq "my_credo" if Rails.application.respond_to?(:credentials)
  end

  it "loads using custom env_prefix" do
    with_env(
      "MYAPP_TEST" => "2",
      "MYAPP_NAME" => "myapp"
    ) do
      data = Anyway::Config.for(:my_app, env_prefix: "MYAPP")
      expect(data[:test]).to eq 2
      expect(data[:name]).to eq "myapp"
    end
  end

  context "when using local files" do
    around do |ex|
      Anyway::Settings.use_local_files = true
      ex.run
      Anyway::Settings.use_local_files = false
    end

    it "load config local credentials too" do
      data = Anyway::Config.for(:my_app)
      expect(data[:test]).to eq 1
      expect(data[:name]).to eq "my_app"
      expect(data[:secret]).to eq "my_secret" if Rails.application.respond_to?(:secrets)
      expect(data[:credo]).to eq "my_credo" if Rails.application.respond_to?(:credentials)
      expect(data[:credo_local]).to eq "betheone" if Rails.application.respond_to?(:credentials)
    end
  end
end
