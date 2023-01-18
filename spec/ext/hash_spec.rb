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

  describe "#deep_transform_keys" do
    let(:source) do
      {
        a: 1,
        'b' => "hello",
        c:
          {
            id: 1
          }
      }
    end

    let(:expected_result) do
      {
        "a - Symbol" => 1,
        "b - String" => "hello",
        "c - Symbol" =>
          {
            "id - Symbol" => 1
          }
      }
    end

    it 'transforms all keys' do
      result = source.deep_transform_keys { |key| "#{key} - #{key.class}" }

      expect(result).to eq(expected_result)
    end
  end
end
