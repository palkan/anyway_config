# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Doppler do
  include Anyway::Testing::Helpers

  subject { described_class.call(**options) }

  let(:options) { {env_prefix: "SOME_APP"} }
  let(:doppler_content) { {"SOME_APP_TOKEN" => "token_value", "ANOTHER_ENV_KEY" => "another_key"} }
  let(:doppler_response) { {"token" => "token_value"} }
  let(:valid_doppler_token) { "valid_bearer_token" }
  let(:invalid_doppler_token) { "invalid_bearer_token" }

  context "when success loads data from doppler" do
    it "loads data from doppler" do
      stub_request(:get, /api.doppler.com/)
        .with(headers: {"Authorization" => "Bearer #{valid_doppler_token}"})
        .to_return(status: 200, body: doppler_content.to_json)

      with_env(
        "DOPPLER_TOKEN" => valid_doppler_token
      ) do
        expect(subject).to eq(doppler_response)
      end
    end
  end

  context "when is missing ENV DOPPLER_TOKEN" do
    it "raises KeyError" do
      expect { subject }.to raise_error(KeyError, /DOPPLER_TOKEN/)
    end
  end

  context "when DOPPLER_TOKEN is not valid" do
    it "raises DOPPLER_REQUEST_ERROR" do
      stub_request(:get, /api.doppler.com/)
        .with(headers: {"Authorization" => "Bearer #{invalid_doppler_token}"})
        .to_return(status: [401, "Unauthorized"])

      with_env(
        "DOPPLER_TOKEN" => invalid_doppler_token
      ) do
        expect { subject }.to raise_error(Anyway::Loaders::Doppler::DOPPLER_REQUEST_ERROR, "401 Unauthorized")
      end
    end
  end
end
