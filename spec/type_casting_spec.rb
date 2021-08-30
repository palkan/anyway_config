# frozen_string_literal: true

require "spec_helper"

describe Anyway::TypeCasting do
  let(:casting) { Anyway::TypeCasting.default.dup }

  specify "default types" do
    expect(casting.deserialize("12", :string)).to eq("12")
    expect(casting.deserialize("12.3", :integer)).to eq(12)
    expect(casting.deserialize("12.3", :float)).to eq(12.3)
    expect(casting.deserialize("2020-08-30 17:01:03", :date)).to eq(Date.parse("2020-08-30"))
    expect(casting.deserialize("2020-08-30 17:01:03", :datetime)).to eq(DateTime.parse("2020-08-30 17:01:03"))
    expect(casting.deserialize("https://github.com/palkan/anyway_config", :uri)).to eq(URI.parse("https://github.com/palkan/anyway_config"))
    expect(casting.deserialize("f", :boolean)).to eq(false)
    expect(casting.deserialize("1,2, 3", :integer, array: true)).to eq([1, 2, 3])
  end

  specify ".accept with block" do
    casting.accept(:string) { _1.capitalize }

    expect(casting.deserialize("test", :string)).to eq("Test")
  end

  specify ".accept without block" do
    klass = Class.new do
      def self.deserialize(val)
        val.downcase
      end
    end

    casting.accept(klass)

    expect(casting.deserialize("TEST", klass)).to eq("test")
  end
end
