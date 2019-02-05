# frozen_string_literal: true

require "spec_norails_helper"

describe Anyway::Config do
  let(:conf) { AnywayTest::Config.new }

  describe "config without Rails" do
    it "has getters", :aggregate_failures do
      expect(conf).to respond_to(:test)
      expect(conf).to respond_to(:api)
      expect(conf).to respond_to(:log)
      expect(conf).to respond_to(:log_levels)
    end

    it "works", :aggregate_failures do
      ENV["ANYWAYTEST_CONF"] = File.join(File.dirname(__FILE__), "anyway.yml")
      ENV["ANYWAYTEST_API__KEY"] = "test1"
      ENV["ANYWAYTEST_TEST"] = "test"
      ENV["ANYWAYTEST_LOG__FORMAT__COLOR"] = "t"
      ENV["ANYWAYTEST_LOG_LEVELS"] = "debug,warning,info"

      expect(conf.api["key"]).to eq "test1"
      expect(conf.api["endpoint"]).to eq "localhost"
      expect(conf.test).to eq "test"
      expect(conf.log["format"]["color"]).to eq true
      expect(conf.log_levels).to eq(%w[debug warning info])
    end

    it "reloads config", :aggregate_failures do
      ENV["ANYWAYTEST_CONF"] = File.join(File.dirname(__FILE__), "anyway.yml")

      expect(conf.api["key"]).to eq ""
      expect(conf.api["endpoint"]).to eq "localhost"
      expect(conf.test).to be_nil
      expect(conf.log["format"]["color"]).to eq false

      ENV["ANYWAYTEST_API__KEY"] = "test1"
      ENV["ANYWAYTEST_API__SSL"] = "yes"
      ENV["ANYWAYTEST_TEST"] = "test"
      ENV["ANYWAYTEST_LOG__FORMAT__COLOR"] = "t"

      Anyway.env.clear

      conf.reload
      expect(conf.api["key"]).to eq "test1"
      expect(conf.api["ssl"]).to eq true
      expect(conf.api["endpoint"]).to eq "localhost"
      expect(conf.test).to eq "test"
      expect(conf.log["format"]["color"]).to eq true
    end

    context "when using local files" do
      around do |ex|
        Anyway::Settings.use_local_files = true
        ex.run
        Anyway::Settings.use_local_files = false
      end

      it "load config local from local file" do
        ENV["ANYWAYTEST_CONF"] = File.join(File.dirname(__FILE__), "anyway.yml")

        expect(conf.api["key"]).to eq "zyx213"
        expect(conf.api["endpoint"]).to eq "localhost"
        expect(conf.test).to be_nil
        expect(conf.log["format"]["color"]).to eq true

        ENV["ANYWAYTEST_API__KEY"] = "test1"
        ENV["ANYWAYTEST_API__SSL"] = "yes"
        ENV["ANYWAYTEST_TEST"] = "test"
        ENV["ANYWAYTEST_LOG__FORMAT__COLOR"] = "t"

        Anyway.env.clear

        conf.reload
        expect(conf.api["key"]).to eq "test1"
        expect(conf.api["ssl"]).to eq true
        expect(conf.api["endpoint"]).to eq "localhost"
        expect(conf.test).to eq "test"
        expect(conf.log["format"]["color"]).to eq true
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

      before(:each) do
        ENV.delete_if { |var| var =~ /cool_/i }
      end

      around do |ex|
        Dir.chdir(File.join(__dir__), &ex)
      end

      it "loads from ./config", :aggregate_failures do
        expect(conf.user).to eq("name" => "root", "password" => "root")
        expect(conf.host).to eq "test.host"
        expect(conf.port).to eq 9292
      end

      it "handle ENV in YML thru ERB" do
        ENV["ANYWAY_COOL_PORT"] = "1957"
        expect(conf.port).to eq 1957
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
end
