# frozen_string_literal: true

require "spec_helper"

describe Anyway::Settings do
  describe "#default_config_path" do
    around do |example|
      was_val = described_class.default_config_path
      example.run
      described_class.default_config_path = was_val
    end

    it "accepts procs" do
      described_class.default_config_path = ->(name) { "#{name}.config.yml" }

      expect(described_class.default_config_path.call("cat")).to eq "cat.config.yml"
    end

    it "accepts strings" do
      described_class.default_config_path = "/etc/configs"

      expect(described_class.default_config_path.call("cat")).to eq "/etc/configs/cat.yml"
    end

    it "accepts pathname" do
      described_class.default_config_path = Pathname.new("/etc/configs")

      expect(described_class.default_config_path.call("cat")).to eq "/etc/configs/cat.yml"
    end
  end
end
