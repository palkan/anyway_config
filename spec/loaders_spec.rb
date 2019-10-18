# frozen_string_literal: true

require "spec_helper"

describe Anyway::Loaders::Registry do
  let(:loader_a) { Object.new }
  let(:loader_b) { Object.new }

  let(:loaders) do
    described_class.new.tap do |reg|
      reg.append :a, loader_a
      reg.append :b, loader_b
    end
  end

  let(:iter) { loaders.each }

  specify "#append with block" do
    loaders.append :c do |_|
      "si"
    end

    iter.next
    iter.next
    expect(iter.next[1].call(0)).to eq "si"
  end

  specify "#append with existing id" do
    expect { loaders.append :a, "a" }.to raise_error(ArgumentError)
  end

  specify "#prepend" do
    loaders.prepend :c, "c"

    expect(iter.next).to eq([:c, "c"])
  end

  specify "#prepend with block" do
    loaders.prepend :c do |_|
      "si"
    end

    expect(iter.next[1].call(0)).to eq "si"
  end

  specify "#insert_before (before first)" do
    loaders.insert_before :a, :c, "c"
    expect(iter.next).to eq([:c, "c"])
  end

  specify "#insert_before (before last)" do
    loaders.insert_before :b, :c, "c"
    iter.next
    expect(iter.next).to eq([:c, "c"])
  end

  specify "#insert_before with non-existing another id" do
    expect { loaders.insert_before :d, :c, "c" }.to raise_error(ArgumentError)
  end

  specify "#insert_before with block" do
    loaders.insert_before :b, :c do |_|
      "si"
    end

    iter.next
    expect(iter.next[1].call(0)).to eq "si"
  end

  specify "#insert_after (after first)" do
    loaders.insert_after :a, :c, "c"
    iter.next
    expect(iter.next).to eq([:c, "c"])
  end

  specify "#insert_after (after last)" do
    loaders.insert_after :b, :c, "c"
    iter.next
    iter.next
    expect(iter.next).to eq([:c, "c"])
  end

  specify "#insert_after with block" do
    loaders.insert_after :b, :c do |_|
      "si"
    end

    iter.next
    iter.next
    expect(iter.next[1].call(0)).to eq "si"
  end

  specify "#override with existing id" do
    loaders.override :a, "a"
    expect(iter.next).to eq([:a, "a"])
  end

  specify "#override with non-existing id" do
    expect { loaders.override :c, "c" }.to raise_error(ArgumentError)
  end

  specify "#delete" do
    loaders.delete :a
    expect(iter.next).to eq([:b, loader_b])
  end

  specify "#delete with non-existing id" do
    expect { loaders.delete :c }.to raise_error(ArgumentError)
  end
end
