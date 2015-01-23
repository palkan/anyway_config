require 'spec_norails_helper'

describe Anyway::Config do
  
  let(:conf) { Anyway::TestConfig.new }

  describe "config without Rails" do
    after(:each) { Anyway.env.clear }
    specify { expect(Anyway::TestConfig.config_name).to eq "anyway" }

    specify do
      expect(conf).to respond_to(:test)
      expect(conf).to respond_to(:api)
    end

    it "should work" do
      ENV['ANYWAY_CONF'] = File.join(File.dirname(__FILE__),"anyway.yml")
      ENV['ANYWAY_API__KEY'] = 'test1'
      ENV['ANYWAY_TEST'] = 'test'

      Anyway.env.reload
      expect(conf.api[:key]).to eq "test1"
      expect(conf.api[:endpoint]).to eq "localhost"
      expect(conf.test).to eq "test"
    end

    it "should reload config" do
      expect(conf.api[:key]).to eq ""
      expect(conf.api[:endpoint]).to be_nil
      expect(conf.test).to be_nil

      ENV['ANYWAY_CONF'] = File.join(File.dirname(__FILE__),"anyway.yml")
      ENV['ANYWAY_API__KEY'] = 'test1'
      ENV['ANYWAY_TEST'] = 'test'
      Anyway.env.reload

      conf.reload
      expect(conf.api[:key]).to eq "test1"
      expect(conf.api[:endpoint]).to eq "localhost"
      expect(conf.test).to eq "test"
    end
  end
end