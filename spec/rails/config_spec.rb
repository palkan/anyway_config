# frozen_string_literal: true

require "spec_helper"

describe Anyway::Config, :rails, type: :config do
  let(:conf) { CoolConfig.new }

  describe "load_from_sources in Rails" do
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

    if !NORAILS
      if Rails.application.respond_to?(:credentials)
        it "load config from credentials" do
          expect(conf.user[:name]).to eq "secret man"
          expect(conf.user[:password]).to eq "root"
        end

        it "sets overrides after loading" do
          config = CoolConfig.new(user: {"password" => "override"})
          expect(config.user[:name]).to eq "secret man"
          expect(config.user[:password]).to eq "override"
        end

        context "with env" do
          specify "env overrides credentials" do
            with_env("COOL_META__KOT" => "zhmot") do
              expect(conf.user[:name]).to eq "secret man"
              expect(conf.meta).to eq("kot" => "zhmot")
              expect(conf.user[:password]).to eq "root"
            end
          end
        end

        context "when using local files", env_kot: false do
          around do |ex|
            Anyway::Settings.use_local_files = true
            ex.run
            Anyway::Settings.use_local_files = false
          end

          it "load config local credentials too" do
            expect(conf.user[:name]).to eq "secret man"
            expect(conf.meta).to eq("kot" => "murkot")
            expect(conf.user[:password]).to eq "password"
          end
        end

        specify "#to_source_trace" do
          # Rails 5 doesn't have credentials config
          credentials_path =
            if ::Rails.application.config.respond_to?(:credentials)
              "config/credentials/test.yml.enc"
            else
              "config/credentials.yml.enc"
            end

          with_env(
            "COOL_USER__PASSWORD" => "secret"
          ) do
            expect(conf).to have_valid_trace
            expect(conf.to_source_trace).to eq(
              {
                "host" => {value: "test.host", source: {type: :yml, path: "config/cool.yml"}},
                "user" => {
                  "name" => {value: "secret man", source: {type: :credentials, store: credentials_path}},
                  "password" => {value: "secret", source: {type: :env, key: "COOL_USER__PASSWORD"}}
                },
                "port" => {value: 8080, source: {type: :defaults}},
                "meta" => {
                  "kot" => {value: "leta", source: {type: :env, key: "COOL_META__KOT"}}
                }
              }
            )
          end
        end
      else
        it "load config from secrets" do
          expect(conf.user[:name]).to eq "test"
          expect(conf.meta).to eq("kot" => "leta")
          expect(conf.user[:password]).to eq "root"
        end

        it "sets overrides after loading secrets" do
          config = CoolConfig.new(user: {"password" => "override"})
          expect(config.user[:name]).to eq "root"
          expect(config.user[:password]).to eq "override"
        end
      end
    else
      it "load config from file if no secrets" do
        expect(conf.user[:name]).to eq "root"
        expect(conf.user[:password]).to eq "root"
      end
    end
  end

  context "validation" do
    specify do
      expect { MyAppConfig.new }
        .to raise_error(Anyway::Config::ValidationError, /missing or empty: name, mode/)
    end

    context "when suppress validation" do
      context "with env" do
        it "skips validation" do
          with_env("SECRET_KEY_BASE_DUMMY" => "true") do
            expect { MyAppConfig.new }.to_not raise_error
          end
        end
      end

      context "with env" do
        it "verifies precedence of envs" do
          with_env(
            "SECRET_KEY_BASE_DUMMY" => "true",
            "ANYWAY_SUPPRESS_VALIDATIONS" => "false"
          ) do
            expect { MyAppConfig.new }
              .to raise_error(Anyway::Config::ValidationError, /missing or empty: name, mode/)
          end
        end
      end

      context "manually with setting" do
        around do |ex|
          Anyway::Settings.suppress_required_validations = true
          ex.run
          Anyway::Settings.suppress_required_validations = false
        end

        it "skips validation" do
          expect { MyAppConfig.new }.to_not raise_error
        end
      end
    end
  end
end
