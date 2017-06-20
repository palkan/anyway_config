# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Config do
  let(:conf) { CoolConfig.new }
  let(:test_conf) { Anyway::TestConfig.new }

  describe "config with name" do
    before(:each) do
      ENV.delete_if { |var| var =~ /^cool_/i }
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

    describe "load from files" do
      it "set defaults" do
        expect(conf.port).to eq 8080
      end

      it "load config from YAML" do
        expect(conf.host).to eq "test.host"
      end

      if Rails.application.respond_to?(:secrets)
        it "load config from secrets" do
          expect(conf.user[:name]).to eq "test"
          expect(conf.user[:password]).to eq "test"
        end
      else
        it "load config from file if no secrets" do
          expect(conf.user[:name]).to eq "root"
          expect(conf.user[:password]).to eq "root"
        end
      end
    end

    describe "load from env" do
      it "work" do
        ENV['COOL_PORT'] = '80'
        ENV['COOL_USER__NAME'] = 'john'
        Anyway.env.clear
        expect(conf.port).to eq 80
        expect(conf.user[:name]).to eq 'john'
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

  describe "config for name" do
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
      if Rails.application.respond_to?(:secrets)
        expect(data[:secret]).to eq 'my_secret'
      end
    end
  end
end
