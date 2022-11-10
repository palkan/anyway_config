# frozen_string_literal: true

require "spec_helper"

describe Anyway::Env, type: :config do
  let(:env) { Anyway.env }

  it "loads simple key/values", :aggregate_failures do
    with_env("TESTO_KEY" => "a", "MY_TEST_KEY" => "b", "TESTOS" => "c") do
      expect(env.fetch("TESTO")).to eq("key" => "a")
      expect(env.fetch("MY_TEST")).to eq("key" => "b")
    end
  end

  it "loads hash values", :aggregate_failures do
    with_env(
      "TESTO_DATA__ID" => "1",
      "TESTO_DATA__META__NAME" => "meta",
      "TESTO_DATA__META__VAL" => "true"
    ) do
      testo_config = env.fetch("TESTO")
      expect(testo_config["data"]["id"]).to eq 1
      expect(testo_config["data"]["meta"]["name"]).to eq "meta"
      expect(testo_config["data"]["meta"]["val"]).to be_truthy
    end
  end

  it "loads array values", :aggregate_failures do
    with_env(
      "TESTO_DATA__IDS" => "1,2, 3",
      "TESTO_DATA__META__NAMES" => "meta, kotleta",
      "TESTO_DATA__META__SIZE" => "2",
      "TESTO_DATA__TEXT" => '"C\'mon, everybody"'
    ) do
      testo_config = env.fetch("TESTO")
      expect(testo_config["data"]["ids"]).to include(1, 2, 3)
      expect(testo_config["data"]["meta"]["names"]).to include("meta", "kotleta")
      expect(testo_config["data"]["meta"]["size"]).to eq 2
      expect(testo_config["data"]["text"]).to eq "C'mon, everybody"
    end
  end

  it "returns deep duped hash" do
    with_env(
      "TESTO_CONF" => "path/to/conf.yml",
      "TESTO_DATA__ID" => "1",
      "TESTO_DATA__META__NAME" => "meta",
      "TESTO_DATA__META__VAL" => "true"
    ) do
      testo_config = env.fetch("TESTO")
      testo_config.delete("conf")
      testo_config["data"]["meta"].delete("name")

      new_config = env.fetch("TESTO")
      expect(new_config["data"]["meta"]["name"]).to eq "meta"
      expect(new_config["conf"]).to eq "path/to/conf.yml"
    end
  end

  context "with trace" do
    it "returns hash and trace" do
      with_env("TESTO_KEY" => "a", "MY_TEST_KEY" => "b", "TESTOS" => "c") do
        conf, trace = env.fetch("TESTO", include_trace: true)
        expect(conf).to eq("key" => "a")
        expect(trace.to_h).to include(
          {"key" => {value: "a", source: {type: :env, key: "TESTO_KEY"}}}
        )
      end
    end
  end
end
