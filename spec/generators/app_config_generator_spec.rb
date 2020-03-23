# frozen_string_literal: true

require "spec_helper"
require "generators/anyway/app_config/app_config_generator"

describe Anyway::Generators::AppConfigGenerator, :rails, type: :generator do
  before(:all) { destination File.join(__dir__, "../../tmp/basic_rails_app") }

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
    let(:target_file) { file("app/configs/api_service_config.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class APIServiceConfig < ApplicationConfig/)
      is_expected.to contain(/attr_config :api_key, :secret, :mode/)
    end
  end
end
