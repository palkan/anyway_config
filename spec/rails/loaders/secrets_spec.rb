# frozen_string_literal: true

require "spec_helper"

describe "Anyway::Rails::Loaders::Secrets", :rails, :secrets, skip: NORAILS || !Rails.application.respond_to?(:secrets) do
  subject { Anyway::Rails::Loaders::Secrets.call(**options) }

  let(:options) { {name: "cool", some_other: "value"} }

  specify do
    expect(subject).to eq(
      {
        user: {
          name: "test"
        },
        bull: "mooo",
        meta: {
          kot: "leta"
        }
      }
    )
  end

  context "when no secrets" do
    let(:options) { {name: "cooler"} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end

  if ENV["DO_NOT_INITIALIZE_RAILS"] == "1"
    it "reset ::Rails.application.secrets state" do
      ::Rails.application.secrets.reset = "me"
      subject
      expect(::Rails.application.secrets.reset).to be_nil
    end
  end
end
