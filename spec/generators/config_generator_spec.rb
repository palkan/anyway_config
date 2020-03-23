# frozen_string_literal: true

require "spec_helper"
require "generators/anyway/config/config_generator"

describe Anyway::Generators::ConfigGenerator, :rails, type: :generator do
  before(:all) { destination File.expand_path("../../tmp", __dir__) }

  let(:args) { %w[api_service api_key secret mode --no-yml] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe "config" do
    subject { file("app/configs/api_service_config.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class APIServiceConfig < ApplicationConfig/)
      is_expected.to contain(/attr_config :api_key, :secret, :mode/)
    end

    context "with --yml" do
      subject { file("config/api_service.yml") }

      let(:args) { %w[api_service api_key secret mode --yml] }

      it "creates a .yml file" do
        is_expected.to exist
        expect(file("app/configs/api_service_config.rb")).to exist
      end

      it "is a valid YAML with env keys" do
        is_expected.to exist

        data = ::YAML.load_file(subject)
        expect(data.keys).to match_array(
          %w[default development test production]
        )
        is_expected.to contain("#  api_key:")
        is_expected.to contain("#  secret:")
        is_expected.to contain("#  mode:")
      end
    end
  end
end
