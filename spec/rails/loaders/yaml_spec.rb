# frozen_string_literal: true

require "spec_helper"

describe "Anyway::Rails::Loaders::YAML", :rails do
  subject { Anyway::Rails::Loaders::YAML.call(**options) }

  let(:path) { Rails.root.join("config/cool.yml") }

  let(:options) { {config_path: path, some_other: "value"} }

  it "parses YAML and eval ERB" do
    expect(subject).to eq(
      {
        "host" => "test.host",
        "user" => {
          "name" => "root",
          "password" => "root"
        }
      }
    )
  end

  context "when the environmental key doesn't match the current environment" do
    let(:options) { {config_path: Rails.root.join("config/cool_unmatched_environment.yml"), some_other: "value"} }

    it "doesn't load any settings for the current environment" do
      expect(subject).to be_empty
    end

    it "loads correct settings if the environment is switched" do
      Rails.env = "production"
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          }
        }
      )
      Rails.env = "test"
    end
  end

  context "when no top environmental keys present" do
    let(:options) { {config_path: Rails.root.join("config/cool_no_environments.yml"), some_other: "value"} }

    it "loads settings for all environments" do
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          }
        }
      )
      Rails.env = "production"
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          }
        }
      )
      Rails.env = "test"
    end
  end

  context "when new known_environment is added to config and used as top-level key" do
    let(:options) { {config_path: Rails.root.join("config/cool_staging_environment.yml"), some_other: "value"} }
    let(:config) { Rails.application.config.anyway_config }

    it "does not leak settings into other environments" do
      config.known_environments << "staging"
      expect(subject).to be_empty
      Rails.env = "development"
      expect(subject).to be_empty
      Rails.env = "production"
      expect(subject).to be_empty
      Rails.env = "test"
    end

    it "picks up settings for new environment" do
      config.known_environments << "staging"
      Rails.env = "staging"
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          }
        }
      )
      Rails.env = "test"
    end
  end

  context "when local is enabled" do
    let(:options) { {config_path: path, local: true, some_other: "value"} }

    specify do
      expect(subject).to eq(
        {
          "host" => "local.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          }
        }
      )
    end
  end
end
