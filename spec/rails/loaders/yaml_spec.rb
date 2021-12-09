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

  context "when known environments disabled" do
    let(:options) { {config_path: Rails.root.join("config/cool_no_environments.yml"), some_other: "value"} }

    it "does not leak settings" do
      expect(subject).to be_empty
    end
  end

  context "when known environments enabled" do
    before { Anyway::Settings.future.use :unwrap_known_environments }
    after do
      Rails.env = "test"
      Anyway::Settings.future.use []
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
      end
    end
  end

  context "default environmental key is set" do
    around do |ex|
      Anyway::Settings.default_environmental_key = "defaults"
      ex.run
      Rails.env = "test"
      Anyway::Settings.default_environmental_key = nil
    end

    context "when only default key is presented" do
      let(:options) { {config_path: Rails.root.join("config/cool_only_default_environment.yml"), some_other: "value"} }

      it "loads defaults" do
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

      context "when known environments enabled" do
        around do |ex|
          Anyway::Settings.future.use :unwrap_known_environments
          ex.run
          Anyway::Settings.future.use []
        end

        it "loads defaults" do
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
      end
    end

    context "when only default environmental key is one of environments" do
      let(:options) { {config_path: Rails.root.join("config/cool_unmatched_environment.yml"), some_other: "value"} }
      before { Anyway::Settings.default_environmental_key = "production" }

      it "loads production as default" do
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
    end

    context "when the environmental key doesn't match the current environment" do
      let(:options) { {config_path: Rails.root.join("config/cool_unmatched_default_environment.yml"), some_other: "value"} }

      it "loads defaults" do
        expect(subject).to eq(
          {
            "host" => "default.host",
            "user" => {
              "name" => "root"
            }
          }
        )
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
      end
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
