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
  let(:doppler_url) { "https://api.doppler.com/v3/configs/config/secrets/download" }

  context "when success loads data from doppler" do
    it "loads data from doppler" do
      stub_request(:get, doppler_url)
        .with(headers: {"Authorization" => "Bearer #{valid_doppler_token}"})
        .to_return(status: 200, body: doppler_content.to_json)

      with_env(
        "DOPPLER_TOKEN" => valid_doppler_token
      ) do
        expect(subject).to eq(doppler_response)
      end
    end

    context "when url and token are specified manually" do
      before do
        allow(described_class).to receive(:download_url) { "http://localhost:4041/env" }
        allow(described_class).to receive(:token) { "my-secret" }
      end

      it "loads data from custom doppler" do
        stub_request(:get, "http://localhost:4041/env")
          .with(headers: {"Authorization" => "Bearer my-secret"})
          .to_return(status: 200, body: doppler_content.to_json)

        expect(subject).to eq(doppler_response)
      end
    end
  end

  context "when is missing ENV DOPPLER_TOKEN" do
    it "raises KeyError" do
      expect { subject }.to raise_error(/Doppler token is required/)
    end
  end

  context "when DOPPLER_TOKEN is not valid" do
    it "raises request error" do
      stub_request(:get, doppler_url)
        .with(headers: {"Authorization" => "Bearer #{invalid_doppler_token}"})
        .to_return(status: [401, "Unauthorized"])

      with_env(
        "DOPPLER_TOKEN" => invalid_doppler_token
      ) do
        expect { subject }.to raise_error(Anyway::Loaders::Doppler::RequestError, "401 Unauthorized")
      end
    end
  end
end
