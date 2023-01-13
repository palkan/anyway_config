# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::EJSON do
  subject { described_class.call(**options) }

  let(:options) { {name:, ejson_adapter:, local: false} }

  # let(:path) { File.join(__dir__, "../config/cool.yml") }
  let(:name) { 'clever' }

  let(:ejson_adapter) do
    adapter = instance_double(Anyway::EJSONAdapter)
    allow(adapter).to receive(:parse).with(config_path).and_return(ejson_parsed_result)
    adapter
  end
  let(:config_path) { "#{Anyway::Settings.app_root}/config/secrets.ejson" }
  let(:ejson_parsed_result) do
    {
      "_public_key"=>"any_public_key",
      "clever" => clever_service_parsed_data,
      "cool" =>
        {
          "_username"=>"5678username",
          "password"=>"5678password"
        }
    }
  end
  let(:clever_service_parsed_data) do
    {
      "_username"=>"1234username",
      "password"=>"1234password"
    }
  end

  context "for apps without environments" do
    before { allow(Anyway::Settings).to receive(:current_environment).and_return(nil) }

    it "parses EJSON" do
      expect(subject).to eq(
        {
          "username"=>"1234username",
          "password"=>"1234password"
        }
      )
    end

    context "when local is enabled" do
      let(:options) { {name:, ejson_adapter:, local: true} }

      let(:local_config_path) { "#{Anyway::Settings.app_root}/config/secrets.local.ejson" }
      let(:local_ejson_parsed_result) do
        {
          "_public_key"=>"any_public_key",
          "clever" =>
            {
              "_username"=>"1234username1234",
              "password"=>"1234password1234"
            },
          "cool" =>
            {
              "_username"=>"5678username5678",
              "password"=>"5678password5678"
            }
        }
      end

      before do
        allow(ejson_adapter).to receive(:parse).with(local_config_path).and_return(local_ejson_parsed_result)
      end

      it 'parses local EJSON config' do
        expect(subject).to eq(
          {
            "username"=>"1234username1234",
            "password"=>"1234password1234"
          }
        )
      end
    end

    context "when parser returns nil" do
      let(:ejson_parsed_result) { nil }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when parsed content is empty" do
      let(:ejson_parsed_result) { {} }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end

    context 'when parsed content contains empty service data' do
      let(:clever_service_parsed_data) { {} }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  # context "with environment" do
  #   let(:path) { File.join(__dir__, "../config/cool.env.yml") }

  #   before { allow(Anyway::Settings).to receive(:current_environment).and_return("development") }

  #   context "loads all keys under current environment section" do
  #     specify do
  #       expect(subject).to eq("host" => "localhost",
  #         "user" => "user",
  #         "log_level" => "debug",
  #         "port" => 80,
  #         "mailer" => {
  #           "host" => "mailhog"
  #         })
  #     end

  #     context "using local file config" do
  #       before { options.merge!(local: true) }

  #       it "overrides env config" do
  #         expect(subject).to eq("host" => "localhost",
  #           "user" => "user",
  #           "log_level" => "info",
  #           "port" => 443,
  #           "mailer" => {
  #             "host" => "mail.google.com"
  #           })
  #       end
  #     end
  #   end
  # end
end
