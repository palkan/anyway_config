# frozen_string_literal: true

require "spec_helper"
require "generators/anyway/install/install_generator"

describe Anyway::Generators::InstallGenerator, :rails, type: :generator do
  before(:all) { destination File.join(__dir__, "../../tmp/basic_rails_app") }

  before do
    prepare_destination
    FileUtils.cp_r(
      File.join(__dir__, "fixtures/basic_rails_app"),
      File.join(__dir__, "../../tmp")
    )
  end

  subject do
    run_generator
    target_file
  end

  describe "application config" do
    let(:target_file) { file("config/configs/application_config.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class ApplicationConfig < Anyway::Config/)
      is_expected.to contain(/delegate_missing_to :instance/)
      is_expected.to contain(/def instance/)
    end

    context "config/application.rb" do
      let(:target_file) { file("config/application.rb") }

      it "contains autoload_static_config_path" do
        is_expected.to exist
        is_expected.to contain("    # config.anyway_config.autoload_static_config_path = \"config/configs\"")
      end
    end

    context ".gitignore" do
      let(:target_file) { file(".gitignore") }

      specify do
        is_expected.to exist
        is_expected.to contain("/config/*.local.yml")
        is_expected.to contain("/config/credentials/local.*")
      end
    end

    context "when autoload_static_config_path is set" do
      let(:target_file) { file("config/settings/application_config.rb") }

      before { allow(Anyway::Settings).to receive(:autoload_static_config_path) { file("config/settings") } }

      it "creates application config in this path" do
        is_expected.to exist
      end
    end
  end
end
