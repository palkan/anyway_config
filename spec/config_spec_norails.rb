require 'spec_norails_helper'

describe Anyway::Config do
  let(:conf) { Anyway::TestConfig.new }

  describe "config without Rails" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^anyway_/i }
      Anyway.env.reload
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

      Anyway.env.reload
      expect(conf.api['key']).to eq "test1"
      expect(conf.api['endpoint']).to eq "localhost"
      expect(conf.test).to eq "test"
      expect(conf.log['format']['color']).to eq true
      expect(conf.log_levels).to eq(%w(debug warning info))
    end

    it "reloads config", :aggregate_failures do
      ENV['ANYWAY_CONF'] = File.join(File.dirname(__FILE__), "anyway.yml")

      expect(conf.api['key']).to eq ""
      expect(conf.api['endpoint']).to be_nil
      expect(conf.test).to be_nil
      expect(conf.log['format']['color']).to eq false
      
      ENV['ANYWAY_API__KEY'] = 'test1'
      ENV['ANYWAY_API__SSL'] = 'yes'
      ENV['ANYWAY_TEST'] = 'test'
      ENV['ANYWAY_LOG__FORMAT__COLOR'] = 't'
      Anyway.env.reload

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

      specify { expect(conf.config_name).to be_nil }
    end
  end
end
