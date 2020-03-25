# frozen_string_literal: true

require "spec_helper"

describe "Anyway::Rails::Loaders::Credentials", :rails, skip: (NORAILS || !Rails.application.respond_to?(:credentials)) do
  subject { Anyway::Rails::Loaders::Credentials.call(**options) }

  let(:options) { {name: "cool", some_other: "value"} }

  specify do
    expect(subject).to eq(
      {
        user: {
          name: "secret man"
        },
        other_stuff: "no need"
      }
    )
  end

  context "when local is enabled" do
    let(:options) { {name: "cool", some_other: "value", local: true} }

    specify do
      expect(subject).to eq(
        {
          user: {
            name: "secret man",
            password: "password"
          },
          other_stuff: "no need",
          meta: {
            kot: "murkot"
          }
        }
      )
    end
  end

  context "when no credentials" do
    let(:options) { {name: "cooler"} }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end
end
