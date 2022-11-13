# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Env do
  include_mock_context "Anyway::Env"

  let(:options) { {env_prefix: "TESTO", some_other: "value"} }

  subject { described_class.call(**options) }

  it "loads data from Anyway::Env" do
    expect(subject).to eq(
      {
        "a" => "x",
        "data" => {
          "key" => "value"
        }
      }
    )
  end

  context "when env has no matching values" do
    let(:options) { {env_prefix: "UNKNOWN"} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end

  context "when env prefix is empty" do
    let(:options) { {env_prefix: ""} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end
end
