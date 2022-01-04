# frozen_string_literal: true

require "spec_helper"
require "generators/anyway/config/config_generator"

describe Anyway::Generators::ConfigGenerator, :rails, type: :generator do
  before(:all) { destination File.join(__dir__, "../../tmp/basic_rails_app") }
  let(:configs_root) { Anyway::Settings.autoload_static_config_path }

  let(:args) { %w[api_service api_key secret mode --no-yml] }

  before do
    prepare_destination
    FileUtils.cp_r(
      File.join(__dir__, "fixtures/basic_rails_app"),
      File.join(__dir__, "../../tmp")
    )
  end

  subject do
    run_generator(args)
    target_file
  end

  describe "config" do
    let(:target_file) { file("#{configs_root}/api_service_config.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class APIServiceConfig < ApplicationConfig/)
      is_expected.to contain(/attr_config :api_key, :secret, :mode/)
    end

    context "with --yml" do
      let(:target_file) { file("config/api_service.yml") }

      let(:args) { %w[api_service api_key secret mode --yml] }

      it "creates a .yml file" do
        is_expected.to exist
        expect(file("#{configs_root}/api_service_config.rb")).to exist
      end

      it "is a valid YAML with env keys" do
        is_expected.to exist

        data = ::YAML.load_file(subject, aliases: true)
        expect(data.keys).to match_array(
          %w[default development test production]
        )
        is_expected.to contain("#  api_key:")
        is_expected.to contain("#  secret:")
        is_expected.to contain("#  mode:")
      end
    end

    context "with --app" do
      let(:target_file) { file("app/configs/api_service_config.rb") }

      let(:args) { %w[api_service api_key secret mode --app --no-yml] }

      it "creates config in app/configs" do
        is_expected.to exist
      end
    end

    context "when autoload_static_config_path is set" do
      let(:target_file) { file("config/settings/api_service_config.rb") }

      before do
        allow(Anyway::Settings).to receive(:autoload_static_config_path) { file("config/settings") }
      end

      it "creates config in this path" do
        is_expected.to exist
      end
    end
  end
end
