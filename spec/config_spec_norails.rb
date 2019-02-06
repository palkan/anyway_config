# frozen_string_literal: true

require "spec_norails_helper"

describe Anyway::Config, type: :config do
  let(:conf) { AnywayTest::Config.new }

  around do |ex|
    with_env("ANYWAYTEST_CONF" => File.join(File.dirname(__FILE__), "anyway.yml"), &ex)
  end

  describe "config without Rails" do
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
end
