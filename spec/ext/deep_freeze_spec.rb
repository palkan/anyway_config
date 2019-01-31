# frozen_string_literal: true

require "spec_helper"
require "anyway/ext/deep_freeze"

describe Anyway::Ext::DeepFreeze do
  using Anyway::Ext::DeepFreeze

  it "freezes nested arrays and hashes", :aggregate_failures do
    source = {
      a: 1,
      b: "hello",
      c: {
        id: 1,
        list: [1, 2, {name: "John"}]
      },
      d: [{id: 1}, {id: 2}]
    }

    dup = source.deep_freeze

    expect(dup).to be_frozen
    expect(dup[:c]).to be_frozen
    expect(dup[:d]).to be_frozen

    expect(dup[:c][:list]).to be_frozen
    expect(dup[:c][:list].last).to be_frozen

    expect(dup[:d].first).to be_frozen
    expect(dup[:d].last).to be_frozen
  end
end
