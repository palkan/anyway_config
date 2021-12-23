# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::YAML do
  subject { described_class.call(**options) }

  let(:path) { File.join(__dir__, "../config/cool.yml") }

  let(:options) { {config_path: path, local: false, some_other: "value"} }

  context 'for apps without environments' do
    before { allow(Anyway::Settings).to receive(:current_environment).and_return(nil) }

    it "parses YAML" do
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          },
          "port" => 9292
        }
      )
    end

    specify "when no ERB available" do
      hide_const("ERB")
      expect(subject).to eq(
        {
          "host" => "test.host",
          "user" => {
            "name" => "root",
            "password" => "root"
          },
          "port" => "<%= ENV['ANYWAY_COOL_PORT'] || 9292 %>"
        }
      )
    end

    context "when local is enabled" do
      let(:options) { {config_path: path, local: true, some_other: "value"} }

      specify do
        expect(subject).to eq(
          {
            "host" => "local.host",
            "user" => {
              "name" => "root",
              "password" => "root"
            },
            "port" => 9292
          }
        )
      end
    end

    context "when file doesn't exist" do
      let(:options) { {config_path: File.join(__dir__, "no.yml")} }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when file is empty" do
      let(:options) { {config_path: File.join(__dir__, "../config/empty.yml")} }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  context 'with environment' do
    let(:path) { File.join(__dir__, "../config/cool.env.yml") }

    before { allow(Anyway::Settings).to receive(:current_environment).and_return('development') }

    context 'loads all keys under current environment section' do
      specify do
        expect(subject).to eq('host' => 'localhost',
                              'user' => 'user',
                              'log_level' => 'debug',
                              'port' => 80,
                              'mailer' => {
                                 'host' => 'mailhog'
                               })
      end

      context 'using local file config' do
        before { options.merge!(local: true) }

        it 'overrides env config' do
          expect(subject).to eq('host' => 'localhost',
                                'user' => 'user',
                                'log_level' => 'info',
                                'port' => 443,
                                'mailer' => {
                                  'host' => 'mail.google.com'
                                })
        end
      end
    end
  end
end
