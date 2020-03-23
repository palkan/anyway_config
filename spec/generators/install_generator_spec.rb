# frozen_string_literal: true

require "spec_helper"
require "generators/anyway/install/install_generator"

describe Anyway::Generators::InstallGenerator, :rails, type: :generator do
  before(:all) { destination File.expand_path("../../tmp", __dir__) }

  before do
    prepare_destination
    File.write(File.join(destination_root, ".gitignore"), "test")
    run_generator
  end

  describe "application config" do
    subject { file("app/configs/application_config.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class ApplicationConfig < Anyway::Config/)
      is_expected.to contain(/delegate_missing_to :instance/)
      is_expected.to contain(/def instance/)
    end

    context ".gitignore" do
      subject { file(".gitignore") }

      specify do
        is_expected.to exist
        is_expected.to contain("/config/*.local.yml")
        is_expected.to contain("/config/credentials/local.*")
      end
    end
  end
end
