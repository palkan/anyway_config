# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Ext::DeepDup do
  using Anyway::Ext::DeepDup

  it "duplicates nested arrays and hashes", :aggregate_failures do
    source = {
      a: 1,
      b: 'hello',
      c: {
        id: 1,
        list: [1, 2, { name: 'John' }]
      },
      d: [{ id: 1 }, { id: 2 }]
    }

    dup = source.deep_dup

    expect(dup[:a]).to eq 1
    expect(dup[:b]).to eq 'hello'
    expect(dup[:c]).to eq(
      id: 1,
      list: [1, 2, { name: 'John' }]
    )
    expect(dup[:d]).to eq(
      [{ id: 1 }, { id: 2 }]
    )

    expect(dup[:c]).not_to be_equal(source[:c])
    expect(dup[:c][:list]).not_to be_equal(source[:c][:list])
    expect(dup[:c][:list].last).not_to be_equal(source[:c][:list].last)

    expect(dup[:d].first).not_to be_equal(source[:d].first)
    expect(dup[:d].last).not_to be_equal(source[:d].last)
  end
end
