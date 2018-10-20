# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Ext::Hash do
  using Anyway::Ext::Hash

  describe "#stringify_keys!" do
    let(:source) do
      {
        a: 1,
        b: 'hello',
        c: {
          id: 1
        }
      }
    end

    let(:expected_result) do
      {
        'a' => 1,
        'b' => 'hello',
        'c' => {
          'id' => 1
        }
      }
    end

    it "transforms keys of hash to strings", :aggregate_failures do
      source.stringify_keys!

      expect(source).to eq(expected_result)
    end

    it "returns a hash with transformed keys to strings", :aggregate_failures do
      expect(source.stringify_keys!).to eq(expected_result)
    end
  end
end
