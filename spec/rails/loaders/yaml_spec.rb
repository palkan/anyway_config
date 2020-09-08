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

  context "when no top environmental keys present" do
    let(:options) { {config_path: Rails.root.join("config/cool_no_environments.yml"), some_other: "value"} }

    it "still loads settings" do
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
