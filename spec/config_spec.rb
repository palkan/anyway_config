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

    context "accessors override" do
      let(:sub_config) do
        Class.new(CoolConfig) do
          attr_config :submeta,
            port: 3000

          def submeta=(val)
            super JSON.parse(val)
          end
        end
      end

      it "supports super" do
        conf = sub_config.new(submeta: '{"a": 1}')

        expect(conf.submeta).to eq("a" => 1)
      end
    end

    context "instance variables" do
      it "populates instance variables in < 2.1.0" do
        if Gem::Version.new(Anyway::VERSION) >= Gem::Version.new("2.1.0")
          expect(conf.host).not_to be_nil
          expect(conf.instance_variable_get(:@host)).to be_nil
        else
          expect(conf.instance_variable_get(:@host)).to eq conf.host

          conf.host = "test.v1"
          expect(conf.instance_variable_get(:@host)).to eq "test.v1"
        end
      end
    end

    describe "#dig" do
      specify do
        expect(conf.dig(:user, "name")).to eq "secret man"
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
            "COOL_USER__NAME" => "Misha",
            "COOL_USER__DOB" => "2019-06-26"
          ) do
            expect(conf.port).to eq 80
            expect(conf.user[:name]).to eq "Misha"
            expect(conf.user[:dob]).to eq(Date.new(2019, 6, 26))
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
            "COOL_ENV_USER__NAME" => "bill",
            "COOL_ENV_HOST" => "2021"
          ) do
            expect(conf.host).to eq "2021"
            expect(conf.port).to eq 8888
            expect(conf.user[:name]).to eq "bill"
          end
        end

        context "with env_prefix = ''" do
          let(:conf) do
            klass = CoolConfig.dup
            klass.env_prefix("")
            klass.new
          end

          it "loads unprefixed env vars" do
            with_env(
              "PORT" => "2004",
              "USER__NAME" => "flo",
              "USER__SOME__FIELD" => "y",
              "HOST" => "stink.ie"
            ) do
              expect(conf.host).to eq "stink.ie"
              expect(conf.port).to eq 2004
              expect(conf.user[:name]).to eq "flo"
              expect(conf.user[:some][:field]).to eq "y"
            end
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

      context "with types" do
        let(:conf) do
          klass = Class.new(CoolConfig)
          klass.coerce_types(port: :string)
          klass.new
        end

        specify { expect(conf.port).to eq "8080" }

        context "with arrays" do
          let(:conf) do
            klass = Class.new(CoolConfig)
            klass.attr_config(hosts: [])
            klass.coerce_types(hosts: {type: :string, array: true})
            klass.new
          end

          specify do
            expect(conf.hosts).to eq []
          end

          specify "with values" do
            with_env(
              "COOL_HOSTS" => "local,dev"
            ) do
              expect(conf.hosts).to eq(%w[local dev])
            end
          end
        end

        context "with boolean" do
          let(:conf) do
            klass = Class.new(CoolConfig)
            klass.attr_config(:booley, :complex_bull, :int_bool)
            klass.coerce_types(booley: :boolean, complex_bull: {type: :boolean}, int_bool: :integer)
            klass.new
          end

          specify do
            expect(conf).not_to be_booley
            expect(conf).not_to be_complex_bull
            expect(conf.respond_to?(:int_bool?)).to be false
          end

          specify "with values" do
            with_env(
              "COOL_BOOLEY" => "1"
            ) do
              expect(conf).to be_booley
              expect(conf).not_to be_complex_bull
            end
          end
        end
      end

      context "when auto cast is disabled" do
        let(:conf) do
          klass = Class.new(CoolConfig)
          klass.disable_auto_cast!
          klass.new
        end

        it "doesn't coerce env values" do
          with_env(
            "COOL_PORT" => "80"
          ) do
            expect(conf.port).to eq "80"
          end
        end
      end
    end

    describe "#clear" do
      let(:conf_cleared) { conf.clear }

      it "nullifies values", :aggregate_failures do
        expect(conf_cleared.meta).to be_nil
        expect(conf_cleared.data).to be_nil
        expect(conf_cleared.host).to be_nil
        expect(conf_cleared.user).to be_nil
        expect(conf_cleared.port).to be_nil
      end
    end

    describe "#reload" do
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

    describe "#as_env" do
      it "returns ENV-like hash" do
        expect(conf.as_env).to eq({"COOL_HOST" => "test.host",
                                   "COOL_META__KOT" => "leta",
                                   "COOL_PORT" => "8080",
                                   "COOL_USER__NAME" => "secret man",
                                   "COOL_USER__PASSWORD" => "root"})
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

    describe "#to_source_trace" do
      let(:conf) { CoolConfig.new }

      around do |ex|
        Dir.chdir(File.join(__dir__), &ex)
      end

      it "with YML data" do
        expect(conf).to have_valid_trace
        expect(conf.to_source_trace).to eq(
          {
            "host" => {value: "test.host", source: {type: :yml, path: "./config/cool.yml"}},
            "user" =>
              {
                "name" => {value: "root", source: {type: :yml, path: "./config/cool.yml"}},
                "password" => {value: "root", source: {type: :yml, path: "./config/cool.yml"}}
              },
            "port" => {value: 9292, source: {type: :yml, path: "./config/cool.yml"}}
          }
        )
      end

      it "with ENV data" do
        with_env(
          "COOL_HOST" => "not_cool.dev",
          "COOL_USER__NAME" => "john"
        ) do
          expect(conf).to have_valid_trace
          expect(conf.to_source_trace).to eq(
            {
              "host" => {value: "not_cool.dev", source: {type: :env, key: "COOL_HOST"}},
              "user" => {
                "name" => {value: "john", source: {type: :env, key: "COOL_USER__NAME"}},
                "password" => {value: "root", source: {type: :yml, path: "./config/cool.yml"}}
              },
              "port" => {value: 9292, source: {type: :yml, path: "./config/cool.yml"}}
            }
          )
        end
      end

      it "with mixed data" do
        with_env(
          "COOL_USER__NAME" => "john"
        ) do
          conf = CoolConfig.new({host: "explicit.dev"})
          expect(conf).to have_valid_trace
          expect(conf.to_source_trace).to eq(
            {
              "host" => {value: "explicit.dev", source: {type: :load}},
              "user" => {
                "name" => {value: "john", source: {type: :env, key: "COOL_USER__NAME"}},
                "password" => {value: "root", source: {type: :yml, path: "./config/cool.yml"}}
              },
              "port" => {value: 9292, source: {type: :yml, path: "./config/cool.yml"}}
            }
          )
        end
      end

      context "when tracing is disabled" do
        around do |ex|
          Anyway::Settings.tracing_enabled = false
          ex.run
          Anyway::Settings.tracing_enabled = true
        end

        it "returns nil" do
          expect(conf.to_source_trace).to be_nil
        end
      end

      context "accessors" do
        it "updates source when value changed" do
          with_env(
            "COOL_USER__NAME" => "john"
          ) do
            expect(conf).to have_valid_trace
            expect(conf.to_source_trace).to eq(
              {
                "host" => {value: "test.host", source: {type: :yml, path: "./config/cool.yml"}},
                "user" => {
                  "name" => {value: "john", source: {type: :env, key: "COOL_USER__NAME"}},
                  "password" => {value: "root", source: {type: :yml, path: "./config/cool.yml"}}
                },
                "port" => {value: 9292, source: {type: :yml, path: "./config/cool.yml"}}
              }
            )

            conf.host = "another.host"
            called_from = "#{__FILE__}:#{__LINE__ - 1}"

            expect(conf.to_source_trace["host"]).to eq(
              {
                value: "another.host",
                source: {
                  type: :accessor,
                  called_from: called_from
                }
              }
            )
          end
        end

        it "creates new value trace if attr wasn't present" do
          expect(conf.data).to be_nil
          expect(conf.to_source_trace["data"]).to be_nil

          conf.data = "some data"
          called_from = "#{__FILE__}:#{__LINE__ - 1}"

          expect(conf.to_source_trace["data"]).to eq(
            {
              value: "some data",
              source: {
                type: :accessor,
                called_from: called_from
              }
            }
          )
        end

        it "creates new hash trace if attr wasn't present" do
          expect(conf.data).to be_nil
          expect(conf.to_source_trace["data"]).to be_nil

          conf.data = {a: "1", b: 2}
          called_from = "#{__FILE__}:#{__LINE__ - 1}"

          expect(conf.to_source_trace["data"]).to eq(
            {
              "a" => {
                value: "1",
                source: {
                  type: :accessor,
                  called_from: called_from
                }
              },
              "b" => {
                value: 2,
                source: {
                  type: :accessor,
                  called_from: called_from
                }
              }
            }
          )
        end
      end
    end

    describe "#pretty_print" do
      let(:overrides) { {} }
      let(:conf) { CoolConfig.new(overrides) }

      around do |ex|
        Dir.chdir(File.join(__dir__), &ex)
      end

      it "contains tracing information", :aggregate_failures do
        overrides[:port] = 3334
        with_env(
          "COOL_USER__NAME" => "john"
        ) do
          expect { pp conf }.to output(
            <<~STR
              #<CoolConfig
                config_name="cool"
                env_prefix="COOL"
                values:
                  port => 3334 (type=load),
                  host => "test.host" (type=yml path=./config/cool.yml),
                  user => { 
                    name => "john" (type=env key=COOL_USER__NAME),
                    password => "root" (type=yml path=./config/cool.yml)
                  }>
            STR
          ).to_stdout
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

    it "only allows alphanumerics", :aggregate_failures, rbs: false do
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

  describe ".required" do
    let(:config) do
      Class.new(described_class) do
        config_name "testo"
        attr_config :test, :secret, debug: false

        required :test, :secret
      end
    end

    context "with nested required attributes" do
      let(:config) do
        Class.new(described_class) do
          config_name "nesty"
          attr_config :test, :secret,
            ldap: {
              base_dn: nil,
              user_dn: nil
            },
            database: {
              host: nil,
              port: nil
            }

          required :test, ldap: [:base_dn, :user_dn], database: [:host]
        end
      end

      let(:values) do
        {
          test: "",
          database: {
            host: "localhost"
          },
          ldap: {
            base_dn: "laladap"
          }
        }
      end

      subject { config.new(values) }

      it "raises ValidationError" do
        expect { subject }.to raise_error(Anyway::Config::ValidationError, %r{missing or empty: test, ldap.user_dn})
      end
    end

    context "with variety of required attributes combinations with env option" do
      before { allow(Anyway::Settings).to receive(:current_environment).and_return("production") }

      let(:app_config) do
        Class.new(described_class) do
          config_name "cool_app"

          attr_config :host, :port, :api_key, :user, :password, :debug, :redis_host
          required :host, :port
          required :api_key, env: "production"
          required :user, :password, env: %w[development production]
          required :redis_host, env: {except: :test}
        end
      end

      let(:demo_config) do
        Class.new(described_class) do
          config_name "demo"
          attr_config :sentry_api_key

          required :sentry_api_key, env: {except: %i[local development test]}
        end
      end

      let(:missed_keys) { [] }
      let(:config_values) do
        {
          api_key: "123",
          user: "john",
          password: "simple",
          redis_host: "localhost:6379",
          host: "localhost",
          port: 80
        }.reject { |k| missed_keys.include?(k) }
      end
      let(:error_msg) { /missing or empty: #{missed_keys.join(', ')}$/ }

      subject { app_config.new(config_values) }

      it "not to raise ValidationError when all values are presence" do
        expect { subject }.to_not raise_error
      end

      shared_examples "raises ValidationError" do
        it "raises ValidationError" do
          expect { subject }.to raise_error(Anyway::Config::ValidationError, error_msg)
        end
      end

      context "when required params without env option is missed" do
        let(:missed_keys) { %i[host port] }

        it_behaves_like "raises ValidationError"
      end

      context "when required env params missed" do
        context "when env param string" do
          let(:missed_keys) { [:api_key] }

          it_behaves_like "raises ValidationError"
        end

        context "when env param symbol" do
          let(:app_config) do
            Class.new(described_class) do
              config_name "app"
              attr_config :host, :port

              required :host, env: :production
            end
          end

          let(:missed_keys) { [:host] }

          it_behaves_like "raises ValidationError"
        end

        context "when env is array of strings" do
          let(:missed_keys) { %i[user password] }

          it_behaves_like "raises ValidationError"
        end

        context "when env param is array of symbols" do
          let(:app_config) do
            Class.new(described_class) do
              config_name "app"
              attr_config :host, :port

              required :host, env: %i[production demo]
            end
          end

          let(:missed_keys) { [:host] }

          it_behaves_like "raises ValidationError"
        end
      end

      context "when current env match env option under except key" do
        before { allow(Anyway::Settings).to receive(:current_environment).and_return("test") }

        let(:missed_keys) { [:redis_host] }

        it "not raises ValidationError" do
          expect { subject }.to_not raise_error
        end
      end

      context "when env value under except key mismatched" do
        before { allow(Anyway::Settings).to receive(:current_environment).and_return("demo") }

        let(:missed_keys) { [:sentry_api_key] }

        it "raises ValidationError" do
          expect { demo_config.new }.to raise_error(Anyway::Config::ValidationError, error_msg)
        end
      end

      context "when current env is not specified" do
        before { allow(Anyway::Settings).to receive(:current_environment).and_return(nil) }

        it "not to raise ValidationError" do
          expect { subject }.to_not raise_error
        end

        it "has specific required keys" do
          expect(subject.class.required_attributes).to match_array(%i[host port redis_host])
        end
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
  end

  describe ".on_load" do
    let(:config) do
      Class.new(described_class) do
        config_name "testo"
        attr_config :test, debug: false

        on_load do
          raise_validation_error("test must be a number") unless test.is_a?(Numeric)
        end
      end
    end

    it "accepts blocks" do
      expect { config.new(test: "nan") }
        .to raise_error(Anyway::Config::ValidationError, /test must be a number/i)
      expect { config.new(test: 12) }
        .not_to raise_error
    end

    context "inheritance" do
      let(:subconfig) do
        Class.new(config) do
          on_load :calibrate_debug

          private

          def calibrate_debug
            self.debug = false if test > 0
          end
        end
      end

      specify do
        expect(subconfig.new(test: 12, debug: true)).not_to be_debug
      end

      specify do
        expect { subconfig.new(test: "nan") }
          .to raise_error(Anyway::Config::ValidationError, /test must be a number/i)
      end
    end
  end

  describe "#deconstruct_keys" do
    let(:config) do
      Class.new(described_class) do
        config_name "testo"
        attr_config :test, :secret, debug: false

        required :test
      end
    end

    specify do
      expect(
        config.new(test: "kis-kis", secret: "meow-meow")
          .deconstruct_keys([:test, :secret])
      ).to eq({test: "kis-kis", secret: "meow-meow", debug: false})
    end

    specify "when attribute wasn't set" do
      expect(
        config.new(test: "as-above-so-below")
          .deconstruct_keys(nil)
      ).to eq({test: "as-above-so-below", debug: false})
    end
  end

  describe "#dup" do
    let(:conf) { CoolConfig.new }

    it "deeply copies values and trace" do
      duped = conf.dup

      expect(duped.class).to eq conf.class
      expect(duped.config_name).to eq conf.config_name
      expect(duped.env_prefix).to eq conf.env_prefix
      expect(duped.to_h).to eq(conf.to_h)
      expect(duped.to_source_trace).to eq(conf.to_source_trace)

      duped.user["password"] = "new_password"
      expect(conf.user["password"]).not_to eq "new_password"

      duped.port = 8089
      expect(conf.to_source_trace["port"][:value]).to eq 8080
    end
  end
end
