# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Doppler do
  include Anyway::Testing::Helpers

  subject { described_class.call }

  let(:doppler_content) { { "some_content" => "success", "some_variable" => "variable" } }

  context "when success loads data from doppler" do
    it "loads data from doppler" do
      http_success = Net::HTTPSuccess.new(1.0, '200', 'OK')

      allow(http_success).to receive(:read_body) { doppler_content.to_json  }
      expect_any_instance_of(Net::HTTP).to receive(:request) { http_success }

      with_env(
        "DOPPLER_TOKEN" => "valid",
      ) do
        expect(subject).to eq(doppler_content)
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
      http_error = Net::HTTPUnauthorized.new(1.0, "401", "Unauthorized")

      expect_any_instance_of(Net::HTTP).to receive(:request) { http_error }

      with_env(
        "DOPPLER_TOKEN" => "not_valid",
      ) do
        expect { subject }.to raise_error(Anyway::Loaders::Doppler::DOPPLER_REQUEST_ERROR, "401 Unauthorized")
      end
    end
  end
end
