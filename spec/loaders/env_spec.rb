# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Env do
  let(:env_double) { instance_double("Anyway::Env") }
  let(:env) do
    {
      "sebya" => "y",
      "hare" => {
        "egg" => "needle"
      }
    }
  end

  let(:options) { {env_prefix: "VNE", some_other: "value"} }

  subject { described_class.call(**options) }

  before do
    allow(::Anyway::Env).to receive(:new).and_return(env_double)
    allow(env_double).to receive(:fetch).and_return([env, nil])
  end

  it "loads data from Anyway::Env" do
    expect(subject).to eq(
      {
        "sebya" => "y",
        "hare" => {
          "egg" => "needle"
        }
      }
    )
    expect(env_double).to have_received(:fetch).with("VNE", include_trace: true)
  end

  context "when env has no matching values" do
    let(:env) { {} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end
end
