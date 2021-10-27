# frozen_string_literal: true

require "spec_helper"

describe Anyway::AutoCast do
  it "serializes a string", :aggregate_failures do
    expect(described_class.call("{\"baz\":\"fizz\",\"baz2\":\"fizz2\"}")).to be_a String
    expect(described_class.call("1,2, 3")).to eq [1, 2, 3]

    expect(described_class.call("t")).to eq true
    expect(described_class.call("true")).to eq true
    expect(described_class.call("y")).to eq true
    expect(described_class.call("yes")).to eq true

    expect(described_class.call("f")).to eq false
    expect(described_class.call("false")).to eq false
    expect(described_class.call("n")).to eq false
    expect(described_class.call("no")).to eq false

    expect(described_class.call("null")).to eq nil
    expect(described_class.call("nil")).to eq nil

    expect(described_class.call("1")).to eq 1

    expect(described_class.call("1.5")).to eq 1.5

    expect(described_class.call("'localhost'")).to eq "localhost"

    expect(described_class.call("localhost")).to eq "localhost"
  end
end
