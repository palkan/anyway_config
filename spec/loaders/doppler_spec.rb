# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Doppler do
  subject { described_class.call(**options) }

  let(:options) { {env_prefix: "vne", some_other: "value"} }

  context "when `DOPPLER_TOKEN` env variable is not specified" do
    before do
      ENV["DOPPLER_TOKEN"] = nil
    end

    it "raises an error" do
      expect { described_class.call(**options) }.to raise_error("Please specify `DOPPLER_TOKEN` env variable")
    end
  end

  context "when the API request fails" do
    before do
      ENV["DOPPLER_TOKEN"] = "token"
      response = double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("404")
      allow(response).to receive(:body).and_return({"messages" => ["some error"]}.to_json)
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it "raises an error" do
      expect { described_class.new(local: false) }.to raise_error("Doppler API error: [\"some error\"]")
    end
  end

  context "when the API request is successful" do
    before do
      ENV["DOPPLER_TOKEN"] = "token"
      response = Net::HTTPSuccess.new("1.1", "200", "OK")
      mocked_body = {
        "vne_sebya" => "y",
        "vneshniy" => "n",
        "vne_hare__egg" => "needle"
      }.to_json
      allow(response).to receive(:body).and_return(mocked_body)
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it "correctly extracts data with prefix" do
      expect(subject).to eq({
        "sebya" => "y",
        "hare" => {
          "egg" => "needle"
        }
      })
    end
  end
end
