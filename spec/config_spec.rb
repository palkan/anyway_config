# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config do
  let(:conf) { CoolConfig.new }
  let(:test_conf) { Anyway::TestConfig.new }

  context "config with explicit name" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^(cool|anyway_test)_/i }
    end

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
        config = CoolConfig.new(overrides: {host: "overrided.host"})
        expect(config.host).to eq "overrided.host"
      end
    end

    describe "load from env" do
      it "handle ENV in YML thru ERB" do
        ENV["ANYWAY_SECRET_PASSWORD"] = "my_pass"
        expect(conf.user[:password]).to eq "my_pass"
      end

      it "overrides loaded value by explicit" do
        ENV["ANYWAY_SECRET_PASSWORD"] = "my_pass"

        config = CoolConfig.new(
          overrides: {
            user: {password: "explicit_password"}
          }
        )
        expect(config.user[:password]).to eq "explicit_password"
      end

      context "when env_prefix is not specified" do
        it "uses config_name as a prefix to load variables" do
          ENV["COOL_PORT"] = "80"
          ENV["COOL_USER__NAME"] = "john"
          Anyway.env.clear
          expect(conf.port).to eq 80
          expect(conf.user[:name]).to eq "john"
        end
      end

      context "when env_prefix is specified" do
        let(:conf) do
          klass = CoolConfig.dup
          klass.env_prefix(:cool_env)
          klass.new
        end

        it "uses env_prefix value as a prefix to load variables" do
          ENV["COOL_PORT"] = "80"
          ENV["COOL_ENV_PORT"] = "8888"
          ENV["COOL_USER__NAME"] = "john"
          ENV["COOL_ENV_USER__NAME"] = "bill"
          expect(conf.port).to eq 8888
          expect(conf.user[:name]).to eq "bill"
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
              env_prefix  :cool_thing
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
        ENV["COOL_PORT"] = "80"
        ENV["COOL_USER__NAME"] = "john"
        Anyway.env.clear
        conf.reload
        expect(conf.port).to eq 80
        expect(conf.user[:name]).to eq "john"
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
    let(:conf) { SmallConfig.new(overrides: {"meta" => "dummy"}) }

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
end
