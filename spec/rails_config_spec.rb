# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config do
  let(:conf) { CoolConfig.new }

  describe "load_from_sources in Rails" do
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

    if Rails.application.respond_to?(:secrets)
      if Rails::VERSION::MAJOR >= 6
        it "load config from secrets and credentials" do
          expect(conf.user[:name]).to eq "secret man"
          expect(conf.meta).to eq("kot" => "leta")
          expect(conf.user[:password]).to eq "root"
        end
      else
        it "load config from secrets" do
          expect(conf.user[:name]).to eq "test"
          expect(conf.meta).to eq("kot" => "leta")
          expect(conf.user[:password]).to eq "root"
        end
      end
    else
      it "load config from file if no secrets" do
        expect(conf.user[:name]).to eq "root"
        expect(conf.user[:password]).to eq "root"
      end
    end
  end
end
