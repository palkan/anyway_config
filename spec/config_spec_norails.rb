# frozen_string_literal: true

require 'spec_norails_helper'

describe Anyway::Config do
  let(:conf) { Anyway::TestConfig.new }

  describe "config without Rails" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^anyway_/i }
    end

    specify { expect(Anyway::TestConfig.config_name).to eq "anyway" }

    it "has getters", :aggregate_failures do
      expect(conf).to respond_to(:test)
      expect(conf).to respond_to(:api)
      expect(conf).to respond_to(:log)
      expect(conf).to respond_to(:log_levels)
    end

    it "works", :aggregate_failures do
      ENV['ANYWAY_CONF'] = File.join(File.dirname(__FILE__), "anyway.yml")
      ENV['ANYWAY_API__KEY'] = 'test1'
      ENV['ANYWAY_TEST'] = 'test'
      ENV['ANYWAY_LOG__FORMAT__COLOR'] = 't'
      ENV['ANYWAY_LOG_LEVELS'] = 'debug,warning,info'

      Anyway.env.clear
      expect(conf.api['key']).to eq "test1"
      expect(conf.api['endpoint']).to eq "localhost"
      expect(conf.test).to eq "test"
      expect(conf.log['format']['color']).to eq true
      expect(conf.log_levels).to eq(%w[debug warning info])
    end

    it "reloads config", :aggregate_failures do
      ENV['ANYWAY_CONF'] = File.join(File.dirname(__FILE__), "anyway.yml")

      expect(conf.api['key']).to eq ""
      expect(conf.api['endpoint']).to eq 'localhost'
      expect(conf.test).to be_nil
      expect(conf.log['format']['color']).to eq false

      ENV['ANYWAY_API__KEY'] = 'test1'
      ENV['ANYWAY_API__SSL'] = 'yes'
      ENV['ANYWAY_TEST'] = 'test'
      ENV['ANYWAY_LOG__FORMAT__COLOR'] = 't'
      Anyway.env.clear

      conf.reload
      expect(conf.api['key']).to eq "test1"
      expect(conf.api['ssl']).to eq true
      expect(conf.api['endpoint']).to eq "localhost"
      expect(conf.test).to eq "test"
      expect(conf.log['format']['color']).to eq true
    end

    context "config without keys" do
      let(:empty_config_class) { Class.new(Anyway::Config) }

      let(:conf) { empty_config_class.new }

      specify { expect { conf.config_name }.to raise_error(ArgumentError) }
    end

    context "loading from default path" do
      let(:conf) { CoolConfig.new }

      before(:each) do
        ENV.delete_if { |var| var =~ /^cool_/i }
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
    end
  end
end
