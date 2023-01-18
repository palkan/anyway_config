# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::EJSON do
  subject { described_class.call(**options) }

  let(:options) { {name: name, ejson_parser: ejson_parser, local: local} }
  let(:name) { "clever" }
  let(:local) { false }

  let(:ejson_parser) do
    parser = instance_double(Anyway::EJSONParser)
    allow(parser).to receive(:call).with(config_path).and_return(ejson_parsed_result)
    allow(parser).to receive(:call).with(local_config_path).and_return(local_ejson_parsed_result)
    allow(parser).to receive(:call).with(development_config_path).and_return(development_ejson_parsed_result)
    parser
  end

  let(:config_path) { "#{Anyway::Settings.app_root}/config/secrets.ejson" }
  let(:ejson_parsed_result) do
    {
      "_public_key" => "any_public_key",
      "clever" => default_parsed_data,
      "cool" =>
        {
          "username" => "5678username",
          "password" => "5678password"
        }
    }
  end
  let(:default_parsed_data) do
    {
      "username" => "default_username",
      "password" => "default_password",
      "connection" =>
        {
          "host" => "default.host",
          "port" => 12345
        }
    }
  end

  let(:local_config_path) { "#{Anyway::Settings.app_root}/config/secrets.local.ejson" }
  let(:local_ejson_parsed_result) do
    {
      "public_key" => "any_public_key",
      "clever" =>
        {
          "password" => "local_password",
          "connection" =>
            {
              "host" => "local.host",
              "port" => 54321
            }
        }
    }
  end

  let(:development_config_path) { "#{Anyway::Settings.app_root}/config/development/secrets.ejson" }
  let(:development_ejson_parsed_result) do
    {
      "public_key" => "any_public_key",
      "clever" =>
        {
          "username" => "development_username",
          "password" => "development_password"
        },
      "cool" =>
        {
          "username" => "8765username8765",
          "password" => "8765password8765"
        }
    }
  end

  context "for apps without environments" do
    before { allow(Anyway::Settings).to receive(:current_environment).and_return(nil) }

    it "parses default EJSON" do
      expect(subject).to eq(default_parsed_data)
    end

    context "when local is enabled" do
      let(:local) { true }

      it "merges local config into default one" do
        expect(subject).to eq(
          "username" => "default_username",
          "password" => "local_password",
          "connection" =>
            {
              "host" => "local.host",
              "port" => 54321
            }
        )
      end
    end

    context "when local is enabled, but there is no secrets.local.ejson file" do
      let(:local) { true }
      let(:local_ejson_parsed_result) { nil }

      it "parses default EJSON config" do
        expect(subject).to eq(default_parsed_data)
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

    context "when parsed content contains empty service data" do
      let(:default_parsed_data) { {} }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  context "with environment" do
    before { allow(Anyway::Settings).to receive(:current_environment).and_return("development") }

    specify do
      expect(subject).to eq(
        "username" => "development_username",
        "password" => "development_password"
      )
    end

    # context "when there is no development config" do
    #   let(:development_ejson_parsed_result) { nil }

    #   it "returns data from default file" do
    #     expect(subject).to eq(default_parsed_data)
    #   end
    # end

    context "using local file config" do
      let(:local) { true }

      it "overrides config with local data" do
        expect(subject).to eq(
          "username" => "development_username",
          "password" => "local_password",
          "connection" =>
            {
              "host" => "local.host",
              "port" => 54321
            }
        )
      end
    end

    context "when local is enabled, but there is no secrets.local.ejson file" do
      let(:local) { true }
      let(:local_ejson_parsed_result) { nil }

      it "parses default EJSON config" do
        expect(subject).to eq(
          "username" => "development_username",
          "password" => "development_password"
        )
      end
    end
  end
end
