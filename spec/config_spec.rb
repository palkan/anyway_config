# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config, type: :config do
  let(:conf) { CoolConfig.new }
  let(:test_conf) { Anyway::TestConfig.new }

  context "config with explicit name", :rails do
    specify { expect(CoolConfig.config_name).to eq "cool" }
    specify { expect(CoolConfig.env_prefix).to eq "COOL" }

    describe "defaults" do
      specify { expect(CoolConfig.defaults[:port]).to eq 8080 }
      specify { expect(CoolConfig.defaults[:host]).to eq "localhost" }
    end

    it "generates accessors", :aggregate_failures do
      expect(conf).to respond_to(:meta)
      expect(conf).to respond_to(:data)
      expect(conf).to respond_to(:port)
      expect(conf).to respond_to(:host)
      expect(conf).to respond_to(:user)
    end

    context "inheritance" do
      let(:sub_config) do
        Class.new(CoolConfig) do
          attr_config :submeta,
            port: 3000
        end
      end

      let(:conf) { sub_config.new }

      it "uses superclass naming", :aggregate_failures do
        expect(sub_config.config_name).to eq "cool"
        expect(sub_config.env_prefix).to eq "COOL"
      end

      it "has its own attributes settings (cloned from parent config)", :aggregate_failures do
        expect(conf).to respond_to(:meta)
        expect(conf).to respond_to(:data)
        expect(conf).to respond_to(:port)
        expect(conf).to respond_to(:host)
        expect(conf).to respond_to(:user)
        expect(conf).to respond_to(:submeta)

        # defaults
        expect(conf.port).to eq 3000
        expect(conf.host).to eq "test.host"
      end
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
        config = CoolConfig.new(host: "overrided.host")
        expect(config.host).to eq "overrided.host"
      end
    end

    describe "load from env" do
      it "handle ENV in YML thru ERB" do
        with_env("ANY_SECRET_PASSWORD" => "my_pass") do
          expect(conf.user[:password]).to eq "my_pass"
        end
      end

      it "overrides loaded value by explicit" do
        with_env("ANY_SECRET_PASSWORD" => "my_pass") do
          config = CoolConfig.new(
            user: {password: "explicit_password"}
          )
          expect(config.user[:password]).to eq "explicit_password"
        end
      end

      context "when env_prefix is not specified" do
        it "uses config_name as a prefix to load variables" do
          with_env(
            "COOL_PORT" => "80",
            "COOL_USER__NAME" => "john"
          ) do
            expect(conf.port).to eq 80
            expect(conf.user[:name]).to eq "john"
          end
        end
      end

      context "when env_prefix is specified" do
        let(:conf) do
          klass = CoolConfig.dup
          klass.env_prefix(:cool_env)
          klass.new
        end

        it "uses env_prefix value as a prefix to load variables" do
          with_env(
            "COOL_PORT" => "80",
            "COOL_ENV_PORT" => "8888",
            "COOL_USER__NAME" => "john",
            "COOL_ENV_USER__NAME" => "bill"
          ) do
            expect(conf.port).to eq 8888
            expect(conf.user[:name]).to eq "bill"
          end
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

        context "when env_name is set" do
          let(:conf) do
            klass = CoolConfig.dup
            klass.class_eval do
              config_name :cool_thing
              env_prefix :cool_thing
            end
            klass.new
          end

          it "doesn't print deprecation warning" do
            expect { conf }.not_to print_warning
          end
        end
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
        with_env(
          "COOL_PORT" => "80",
          "COOL_USER__NAME" => "john"
        ) do
          conf.reload
          expect(conf.port).to eq 80
          expect(conf.user[:name]).to eq "john"
        end
      end
    end
  end

  context "without Rails", :norails do
    let(:conf) { AnywayTest::Config.new }

    around do |ex|
      with_env("ANYWAYTEST_CONF" => File.join(File.dirname(__FILE__), "anyway.yml"), &ex)
    end

    it "has getters", :aggregate_failures do
      expect(conf).to respond_to(:test)
      expect(conf).to respond_to(:api)
      expect(conf).to respond_to(:log)
      expect(conf).to respond_to(:log_levels)
    end

    it "works", :aggregate_failures do
      with_env(
        "ANYWAYTEST_API__KEY" => "test1",
        "ANYWAYTEST_TEST" => "test",
        "ANYWAYTEST_LOG__FORMAT__COLOR" => "t",
        "ANYWAYTEST_LOG_LEVELS" => "debug,warning,info"
      ) do
        expect(conf.api["key"]).to eq "test1"
        expect(conf.api["endpoint"]).to eq "localhost"
        expect(conf.test).to eq "test"
        expect(conf.log["format"]["color"]).to eq true
        expect(conf.log_levels).to eq(%w[debug warning info])
      end
    end

    it "reloads config", :aggregate_failures do
      expect(conf.api["key"]).to eq ""
      expect(conf.api["endpoint"]).to eq "localhost"
      expect(conf.test).to be_nil
      expect(conf.log["format"]["color"]).to eq false

      with_env(
        "ANYWAYTEST_API__KEY" => "test1",
        "ANYWAYTEST_API__SSL" => "yes",
        "ANYWAYTEST_TEST" => "test",
        "ANYWAYTEST_LOG__FORMAT__COLOR" => "t"
      ) do
        conf.reload
        expect(conf.api["key"]).to eq "test1"
        expect(conf.api["ssl"]).to eq true
        expect(conf.api["endpoint"]).to eq "localhost"
        expect(conf.test).to eq "test"
        expect(conf.log["format"]["color"]).to eq true
      end
    end

    context "when using local files" do
      around do |ex|
        Anyway::Settings.use_local_files = true
        ex.run
        Anyway::Settings.use_local_files = false
      end

      it "load config local from local file" do
        expect(conf.api["key"]).to eq "zyx213"
        expect(conf.api["endpoint"]).to eq "localhost"
        expect(conf.test).to be_nil
        expect(conf.log["format"]["color"]).to eq true

        with_env(
          "ANYWAYTEST_API__KEY" => "test1",
          "ANYWAYTEST_API__SSL" => "yes",
          "ANYWAYTEST_TEST" => "test",
          "ANYWAYTEST_LOG__FORMAT__COLOR" => "t"
        ) do
          conf.reload
          expect(conf.api["key"]).to eq "test1"
          expect(conf.api["ssl"]).to eq true
          expect(conf.api["endpoint"]).to eq "localhost"
          expect(conf.test).to eq "test"
          expect(conf.log["format"]["color"]).to eq true
        end
      end
    end

    context "config without keys" do
      let(:empty_config_class) { Class.new(Anyway::Config) }

      it "raises error" do
        expect { empty_config_class.new }.to raise_error(/specify config name explicitly/)
      end
    end

    context "loading from default path" do
      let(:conf) { CoolConfig.new }

      around do |ex|
        Dir.chdir(File.join(__dir__), &ex)
      end

      it "loads from ./config", :aggregate_failures do
        expect(conf.user).to eq("name" => "root", "password" => "root")
        expect(conf.host).to eq "test.host"
        expect(conf.port).to eq 9292
      end

      it "handle ENV in YML thru ERB" do
        with_env("ANYWAY_COOL_PORT" => "1957") do
          expect(conf.port).to eq 1957
        end
      end

      context "when using local files" do
        around do |ex|
          Anyway::Settings.use_local_files = true
          ex.run
          Anyway::Settings.use_local_files = false
        end

        it "load config local from local file" do
          expect(conf.user).to eq("name" => "root", "password" => "root")
          expect(conf.host).to eq "local.host"
          expect(conf.port).to eq 9292
        end
      end
    end
  end

  describe ".config_name" do
    specify "<SomeModule>::Config", :aggregate_failures do
      expect(AnywayTest::Config.config_name).to eq "anywaytest"
      expect(AnywayTest::Config.env_prefix).to eq "ANYWAYTEST"
    end

    specify "<Some>Config" do
      expect(SmallConfig.config_name).to eq "small"
      expect(SmallConfig.env_prefix).to eq "SMALL"
    end

    context "anonymous" do
      let(:config) do
        Class.new(described_class)
      end

      it "raises error" do
        expect { config.new }.to raise_error(/specify config name explicitly/)
      end
    end

    context "non-inferrable name" do
      let(:config) do
        Class.new(described_class) do
          def self.name
            "Some::Nested::Config"
          end
        end
      end

      it "raises error" do
        expect { config.new }.to raise_error(/specify .+ explicitly/)
      end
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
    let(:conf) { SmallConfig.new("meta" => "dummy") }

    it "works" do
      expect(conf.meta).to eq "dummy"
    end
  end

  context "extending config" do
    let(:config) do
      Class.new(described_class) do
        config_name "testo"
        attr_config :test, debug: false
      end
    end

    it "adds new params" do
      old_config = config.new

      expect(old_config.debug).to eq false
      expect(old_config.test).to be_nil

      config.attr_config new_param: "a"

      new_config = config.new
      expect(new_config.debug).to eq false
      expect(new_config.test).to be_nil
      expect(new_config.new_param).to eq "a"
    end
  end

  context "params naming" do
    it "disallow reserved names" do
      expect { Class.new(described_class) { attr_config :values, :load } }
        .to raise_error(ArgumentError, /reserved names.+: load, values/)
    end

    it "only allows alphanumerics", :aggregate_failures do
      expect { Class.new(described_class) { attr_config "1a" } }
        .to raise_error(ArgumentError, /invalid attr_config name: 1a/i)
      expect { Class.new(described_class) { attr_config :a? } }
        .to raise_error(ArgumentError, /invalid attr_config name: a?/i)
      expect { Class.new(described_class) { attr_config :_d } }

      expect { Class.new(described_class) { attr_config :x } }
        .not_to raise_error
      expect { Class.new(described_class) { attr_config "a1" } }
        .not_to raise_error
    end
  end

  context "required parameters" do
    let(:config) do
      Class.new(described_class) do
        config_name "testo"
        attr_config :test, :secret, debug: false

        required :test, :secret
      end
    end

    it "raises ValidationError if value is not provided" do
      expect { config.new }
        .to raise_error(Anyway::Config::ValidationError, /missing or empty: test, secret/)
    end

    it "raises ValidationError if value is empty string" do
      expect { config.new(secret: "", test: 1) }
        .to raise_error(Anyway::Config::ValidationError, /missing or empty: secret/)
    end

    it "raises ArgumentError if required is called with unknown param" do
      expect { Class.new(described_class) { required :test } }
        .to raise_error(ArgumentError, /unknown config param: test/i)
    end

    specify "inheritance" do
      subconfig = Class.new(config) { required :debug }

      expect { subconfig.new }
        .to raise_error(Anyway::Config::ValidationError, /missing or empty: test, secret/)
    end

    context "with custom validation method" do
      let(:config) do
        Class.new(described_class) do
          config_name "testo"
          attr_config :test, debug: false

          required :test

          def validate!
            super
            raise_validation_error("test must be a number") unless test.is_a?(Numeric)
          end
        end
      end

      it "calls #validate! method" do
        expect { config.new(test: "nan") }
          .to raise_error(Anyway::Config::ValidationError, /test must be a number/i)
      end
    end
  end
end
