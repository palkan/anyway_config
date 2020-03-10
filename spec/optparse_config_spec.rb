# frozen_string_literal: true

require "spec_helper"
require "json"

describe Anyway::Config do
  describe "#parse_options!" do
    let(:config_instance) { config.new }

    context "when `ignore_options` is not provided" do
      let(:config) do
        Class.new(described_class) do
          config_name "optparse"
          attr_config :host, :port, :log_level, :debug
          flag_options :debug
        end
      end

      it "parses ARGC string" do
        config_instance.parse_options!(%w[--host localhost --port 3333 --log-level debug --debug])
        expect(config_instance.host).to eq("localhost")
        expect(config_instance.port).to eq(3333)
        expect(config_instance.log_level).to eq("debug")
        expect(config_instance.debug).to eq(true)
      end
    end

    context "when `ignore_options` is provided" do
      let(:config) do
        Class.new(described_class) do
          config_name "optparse"
          attr_config :host, :log_level, :concurrency, server_args: {}

          ignore_options :server_args
        end
      end

      it "parses ARGC string" do
        expect do
          config_instance.parse_options!(
            %w[--host localhost --concurrency 10 --log-level debug --server-args SOME_ARGS]
          )
        end.to raise_error(OptionParser::InvalidOption, /--server-args/)

        expect(config_instance.host).to eq("localhost")
        expect(config_instance.concurrency).to eq(10)
        expect(config_instance.log_level).to eq("debug")
        expect(config_instance.server_args).to eq({})
      end
    end

    context "when `describe_options` is provided" do
      let(:config) do
        Class.new(described_class) do
          config_name "optparse"
          attr_config :host, :log_level, :concurrency, server_args: {}

          describe_options(
            concurrency: "number of threads to use"
          )
        end
      end

      it "contains options description" do
        expect(config_instance.option_parser.help).to include("number of threads to use")
      end
    end

    context "customization of option parser" do
      let(:config) do
        Class.new(described_class) do
          config_name "optparse"
          attr_config :host, :log_level, :concurrency, server_args: {}

          extend_options do |parser, config|
            parser.banner = "mycli [options]"

            parser.on("--server-args VALUE") do |value|
              config.server_args = JSON.parse(value)
            end

            parser.on_tail "-h", "--help" do
              puts parser
            end
          end
        end
      end

      it "allows to customize the parser" do
        expect(config_instance.option_parser.help).to include("mycli [options]")
      end

      it "passes config to extension" do
        config_instance.parse_options!(
          ["--server-args", '{"host":"0.0.0.0"}']
        )
        expect(config_instance.server_args["host"]).to eq "0.0.0.0"
      end

      context "inheritance" do
        let(:sub_config) do
          Class.new(config) do
            attr_config :test

            ignore_options :test

            extend_options do |parser, config|
              parser.banner = "my_another_cli [options]"

              parser.on("--testo VALUE") do |value|
                config.test = value == "1"
              end
            end
          end
        end

        let(:config_instance) { sub_config.new }

        it "overrides banner" do
          expect(config_instance.option_parser.help).to include("my_another_cli [options]")
        end

        it "passes config to extension" do
          config_instance.parse_options!(
            ["--server-args", '{"host":"0.0.0.0"}',
             "--testo", "1"]
          )
          expect(config_instance.server_args["host"]).to eq "0.0.0.0"
          expect(config_instance.test).to eq true
        end
      end
    end
  end
end
