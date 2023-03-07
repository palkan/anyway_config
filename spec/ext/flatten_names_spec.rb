# frozen_string_literal: true

require "spec_helper"

describe Anyway::Ext::FlattenNames do
  using Anyway::Ext::FlattenNames

  describe "#flatten_names" do
    specify do
      expect({a: [:b, :c], d: [:x, y: {t: [:r]}]}.flatten_names).to eq(
        [
          :"a.b",
          :"a.c",
          :"d.x",
          :"d.y.t.r"
        ]
      )
    end

    specify do
      expect({a: [], d: {e: []}}.flatten_names).to eq(
        [
          :a,
          :"d.e"
        ]
      )
    end
  end
end
