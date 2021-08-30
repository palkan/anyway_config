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

          coerce_types port: :string
        end
      end

      it "parses args" do
        config_instance.parse_options!(%w[--host localhost --port 3333 --log-level debug --debug])
        expect(config_instance.host).to eq("localhost")
        expect(config_instance.port).to eq("3333")
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

      it "parses args" do
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

      context "with types" do
        let(:config) do
          Class.new(described_class) do
            config_name "optparse"
            attr_config :host, :log_level, :concurrency, server_args: {}

            # Coercion overrides options types
            coerce_types concurrency: :float

            describe_options(
              concurrency: {
                desc: "number of threads to use",
                type: String
              }
            )
          end
        end

        it "uses specified type information" do
          config_instance.parse_options!(%w[--host localhost --concurrency 10])
          expect(config_instance.concurrency).to eq 10
        end
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
            ["--server-args", '{"host":"0.0.0.0"}', "--testo", "1"]
          )
          expect(config_instance.server_args["host"]).to eq "0.0.0.0"
          expect(config_instance.test).to eq true
        end
      end
    end
  end

  describe "#to_source_trace" do
    let(:config) do
      Class.new(described_class) do
        config_name "optparse"
        attr_config :host, :port, verbose: false, log_level: :info, debug: false
        flag_options :debug

        extend_options do |parser, config|
          parser.on("-V") do |value|
            config.verbose = value
          end
        end
      end
    end

    let(:conf) { config.new }

    it "contains optparse info" do
      conf.parse_options!(%w[--host localhost --port 3333 -V])
      expect(conf).to have_valid_trace
      expect(conf.to_source_trace).to eq(
        {
          "host" => {value: "localhost", source: {type: :options}},
          "port" => {value: 3333, source: {type: :options}},
          "log_level" => {value: :info, source: {type: :defaults}},
          "debug" => {value: false, source: {type: :defaults}},
          "verbose" => {value: true, source: {type: :options}}
        }
      )
    end
  end
end
