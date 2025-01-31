# frozen_string_literal: true

require "spec_helper"

describe Anyway::TypeRegistry do
  let(:casting) { Anyway::TypeRegistry.default.dup }

  specify "default types" do
    expect(casting.deserialize("12", :string)).to eq("12")
    expect(casting.deserialize("12.3", :integer)).to eq(12)
    expect(casting.deserialize("12", :integer!)).to eq(12)
    expect { casting.deserialize("12.3", :integer!) }.to raise_error(ArgumentError, /invalid value for Integer()/)
    expect(casting.deserialize("12.3", :float)).to eq(12.3)
    expect(casting.deserialize("2020-08-30 17:01:03", :date)).to eq(Date.parse("2020-08-30"))
    expect(casting.deserialize(Time.local(2020, 8, 30, 11, 44, 22), :date)).to eq(Date.parse("2020-08-30"))
    expect(casting.deserialize("2020-08-30 17:01:03", :datetime)).to eq(DateTime.parse("2020-08-30 17:01:03"))
    expect(casting.deserialize("https://github.com/palkan/anyway_config", :uri)).to eq(URI.parse("https://github.com/palkan/anyway_config"))
    expect(casting.deserialize("f", :boolean)).to eq(false)
    expect(casting.deserialize(1, :boolean)).to eq(true)
    expect(casting.deserialize("1,2, 3", :integer, array: true)).to eq([1, 2, 3])
    expect(casting.deserialize(nil, :integer, array: true)).to eq(nil)
    expect(casting.deserialize(1, nil, array: true)).to eq([1])
    expect(casting.deserialize([1], nil, array: true)).to eq([1])
  end

  specify ".accept with block" do
    casting.accept(:string, &:capitalize)

    expect(casting.deserialize("test", :string)).to eq("Test")
  end

  specify ".accept without block" do
    klass = Class.new do
      def self.call(val)
        val.downcase
      end
    end

    casting.accept(klass)

    expect(casting.deserialize("TEST", klass)).to eq("test")
  end

  describe Anyway::TypeCaster do
    let(:colorName) do
      lambda do |raw|
        case raw
        when "red"
          "#ff0000"
        when "green"
          "#00ff00"
        when "blue"
          "#0000ff"
        end
      end
    end

    let(:type_caster) do
      described_class.new({
        non_list: :string,
        hare: {
          legs: {
            type: :string,
            array: true
          },
          age: :float
        },
        color: colorName
      },
        fallback: ::Anyway::AutoCast)
    end

    it "uses mapping", :aggregate_failures do
      expect(type_caster.coerce("non_list", "1, 2")).to eq("1, 2")
      expect(type_caster.coerce("list", "1, 2")).to eq([1, 2])
      expect(type_caster.coerce("hare", {"legs" => "1, 4", "age" => "3.25", "name" => "Zai"}))
        .to eq({"legs" => ["1", "4"], "age" => 3.25, "name" => "Zai"})
      expect(type_caster.coerce("color", "blue")).to eq("#0000ff")
    end
  end
end
