# frozen_string_literal: true

require "spec_helper"

describe Anyway::Ext::Hash do
  using Anyway::Ext::Hash

  describe "#stringify_keys!" do
    let(:source) do
      {
        a: 1,
        b: "hello",
        c: {
          id: 1
        }
      }
    end

    let(:expected_result) do
      {
        "a" => 1,
        "b" => "hello",
        "c" => {
          "id" => 1
        }
      }
    end

    it "transforms keys of hash to strings" do
      source.stringify_keys!

      expect(source).to eq(expected_result)
    end

    it "returns a hash with transformed keys to strings" do
      expect(source.stringify_keys!).to eq(expected_result)
    end
  end

  describe "#deep_merge!" do
    specify do
      h = {a: {b: 2, e: 6}, c: 3, x: {y: 5}}
      h.deep_merge!({a: {b: 3, d: 4}, c: {f: 6}, x: 2021})

      expect(h).to eq({a: {b: 3, d: 4, e: 6}, c: {f: 6}, x: 2021})
    end
  end
end
