# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Env do
  include Anyway::Testing::Helpers

  subject { described_class.call(**options) }

  let(:options) { {env_prefix: "VNE", some_other: "value"} }

  it "loads data from env" do
    with_env(
      "VNE_SEBYA" => "y",
      "VNESHNIY" => "n",
      "VNE_HARE__EGG" => "needle"
    ) do
      expect(subject).to eq(
        {
          "sebya" => "y",
          "hare" => {
            "egg" => "needle"
          }
        }
      )
    end
  end

  context "when env has no matching values" do
    let(:options) { {env_prefix: "VNE" * 4} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end
end
