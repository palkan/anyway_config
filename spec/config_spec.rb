# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Config do
  let(:conf) { CoolConfig.new }
  let(:test_conf) { Anyway::TestConfig.new }

  context "config with name" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^(cool|anyway)_/i }
    end

    specify { expect(CoolConfig.config_name).to eq "cool" }

    describe "defaults" do
      specify { expect(CoolConfig.defaults[:port]).to eq 8080 }
      specify { expect(CoolConfig.defaults[:host]).to eq 'localhost' }
    end

    it "generates accessors", :aggregate_failures do
      expect(conf).to respond_to(:meta)
      expect(conf).to respond_to(:data)
      expect(conf).to respond_to(:port)
      expect(conf).to respond_to(:host)
      expect(conf).to respond_to(:user)
    end

    describe "#to_h" do
      subject(:config) { CoolConfig.new }

      it "returns deeply frozen hash" do
        hashed = config.to_h

        expect(hashed).to be_a(Hash)
        expect(hashed).to be_frozen
        expect(hashed[:user]).to be_frozen
      end

      it "returns new hash every time" do
        hashed = config.to_h
        hashed2 = config.to_h

        expect(hashed).to be_eql(hashed2)
      end
    end

    describe "load from files" do
      it "set defaults" do
        expect(conf.port).to eq 8080
      end

      it "load config from YAML" do
        expect(conf.host).to eq "test.host"
      end

      it "sets overrides after loading YAML" do
        config = CoolConfig.new(overrides: { host: 'overrided.host' })
        expect(config.host).to eq "overrided.host"
      end

      if Rails.application.respond_to?(:secrets)
        it "load config from secrets" do
          expect(conf.user[:name]).to eq "test"
        end
      else
        it "load config from file if no secrets" do
          expect(conf.user[:name]).to eq "root"
          expect(conf.user[:password]).to eq "root"
        end
      end
    end

    describe "load from env" do
      context "when env_prefix is not specified" do
        it "uses config_name as a prefix to load variables" do
          ENV['COOL_PORT'] = '80'
          ENV['COOL_USER__NAME'] = 'john'
          Anyway.env.clear
          expect(conf.port).to eq 80
          expect(conf.user[:name]).to eq 'john'
        end
      end

      context "when env_prefix is specified" do
        let(:conf) do
          klass = CoolConfig.dup
          klass.class_eval { env_prefix(:cool_env) }
          klass.new
        end

        it "uses env_prefix value as a prefix to load variables" do
          ENV['COOL_PORT'] = '80'
          ENV['COOL_ENV_PORT'] = '8888'
          ENV['COOL_USER__NAME'] = 'john'
          ENV['COOL_ENV_USER__NAME'] = 'bill'
          Anyway.env.clear
          expect(conf.port).to eq 8888
          expect(conf.user[:name]).to eq 'bill'
        end
      end

      context "when config_name contains underscores" do
        let(:conf) do
          klass = CoolConfig.dup
          klass.class_eval do
            config_name :cool_thing
          end
          klass.new
        end

        it "warns user about deprecated behaviour" do
          expect { conf }.to print_warning
        end

        context "when env_name is set" do
          let(:conf) do
            klass = CoolConfig.dup
            klass.class_eval do
              config_name :cool_thing
              env_prefix  :cool_thing
            end
            klass.new
          end

          it "doesn't print deprecation warning" do
            expect { conf }.not_to print_warning
          end
        end
      end

      it "handle ENV in YML thru ERB" do
        ENV['ANYWAY_SECRET_PASSWORD'] = 'my_pass'
        expect(conf.user[:password]).to eq 'my_pass'
      end

      it "overrides loaded value by explicit" do
        ENV['ANYWAY_SECRET_PASSWORD'] = 'my_pass'

        config = CoolConfig.new(
          overrides: {
            user: { password: 'explicit_password' }
          }
        )
        expect(config.user[:password]).to eq "explicit_password"
      end
    end

    describe "clear" do
      let(:conf_cleared) { conf.clear }

      it "nullifies values", :aggregate_failures do
        expect(conf_cleared.meta).to be_nil
        expect(conf_cleared.data).to be_nil
        expect(conf_cleared.host).to be_nil
        expect(conf_cleared.user).to be_nil
        expect(conf_cleared.port).to be_nil
      end
    end

    describe "reload" do
      it do
        expect(conf.port).to eq 8080
        ENV['COOL_PORT'] = '80'
        ENV['COOL_USER__NAME'] = 'john'
        Anyway.env.clear
        conf.reload
        expect(conf.port).to eq 80
        expect(conf.user[:name]).to eq 'john'
      end
    end
  end

  context "config for name" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^myapp_/i }
    end

    it "load data by config name", :aggregate_failures do
      ENV['MYAPP_TEST'] = '1'
      ENV['MYAPP_NAME'] = 'my_app'
      Anyway.env.clear
      data = Anyway::Config.for(:my_app)
      expect(data[:test]).to eq 1
      expect(data[:name]).to eq 'my_app'
      expect(data[:secret]).to eq 'my_secret' if Rails.application.respond_to?(:secrets)
    end
  end

  context "config without defaults" do
    let(:conf) { SmallConfig.new }

    it "works" do
      expect(conf.meta).to be_nil
      expect(conf.data).to be_nil
    end
  end

  context "config with initial hash values" do
    let(:conf) { SmallConfig.new(overrides: { 'meta': 'dummy' }) }

    it "works" do
      expect(conf.meta).to eq 'dummy'
    end
  end

  context "when name is missing" do
    let(:config) do
      Class.new(described_class)
    end

    it "raises ArgumentError" do
      expect { config.new }.to raise_error(ArgumentError)
    end
  end

  context "extending config" do
    let(:config) do
      Class.new(described_class) do
        config_name 'testo'
        attr_config :test, debug: false
      end
    end

    it "adds new params" do
      old_config = config.new

      expect(old_config.debug).to eq false
      expect(old_config.test).to be_nil

      config.attr_config new_param: 'a'

      new_config = config.new
      expect(new_config.debug).to eq false
      expect(new_config.test).to be_nil
      expect(new_config.new_param).to eq 'a'
    end
  end

  describe "#parse_options!" do
    let(:config_instance) { config.new }

    context "when `ignore_options` is not provided" do
      let(:config) do
        Class.new(described_class) do
          config_name 'optparse'
          attr_config :host, :port, :log_level, :debug
        end
      end

      it "parses ARGC string" do
        config_instance.parse_options!(%w[--host localhost --port 3333 --log-level debug --debug T])
        expect(config_instance.host).to eq("localhost")
        expect(config_instance.port).to eq(3333)
        expect(config_instance.log_level).to eq("debug")
        expect(config_instance.debug).to eq(true)
      end
    end

    context 'when `ignore_options` is provided' do
      let(:config) do
        Class.new(described_class) do
          config_name 'optparse'
          attr_config :host, :log_level, :concurrency, server_args: {}

          ignore_options :server_args
        end
      end

      it "parses ARGC string" do
        config_instance.parse_options!(
          %w[--host localhost --concurrency 10 --log-level debug --server-args SOME_ARGS]
        )
        expect(config_instance.host).to eq("localhost")
        expect(config_instance.concurrency).to eq(10)
        expect(config_instance.log_level).to eq("debug")
        expect(config_instance.server_args).to eq({})
      end
    end

    context 'when `describe_options` is provided' do
      let(:config) do
        Class.new(described_class) do
          config_name 'optparse'
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
          config_name 'optparse'
          attr_config :host, :log_level, :concurrency, server_args: {}

          extend_options do |parser|
            parser.banner = "mycli [options]"

            parser.on_tail "-h", "--help" do
              puts parser
            end
          end
        end

        it "allows to customize the parser" do
          expect(config_instance.option_parser.help).to include("mycli [options]")
        end
      end
    end
  end
end
