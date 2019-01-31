# frozen_string_literal: true

require "spec_helper"

describe Anyway::Ext::StringSerialize do
  using Anyway::Ext::StringSerialize

  it "serializes a string", :aggregate_failures do
    expect("1,2, 3".serialize).to eq [1, 2, 3]

    expect("t".serialize).to eq true
    expect("true".serialize).to eq true
    expect("y".serialize).to eq true
    expect("yes".serialize).to eq true

    expect("f".serialize).to eq false
    expect("false".serialize).to eq false
    expect("n".serialize).to eq false
    expect("no".serialize).to eq false

    expect("null".serialize).to eq nil
    expect("nil".serialize).to eq nil

    expect("1".serialize).to eq 1

    expect("1.5".serialize).to eq 1.5

    expect("'localhost'".serialize).to eq "localhost"

    expect("localhost".serialize).to eq "localhost"
  end
end
