# frozen_string_literal: true

require "spec_helper"

describe Anyway::Testing::Helpers, type: :config do
  after { ENV.delete_if { |k, _| k =~ /^rspeco_/ } }

  specify do
    ENV["RSPECO_ONE"] = "1"
    ENV["RSPECO_TWO"] = "duo"

    expect(Anyway.env.fetch("RSPECO")).to eq({
      "one" => 1,
      "two" => "duo"
    })

    with_env("RSPECO_ONE" => "ein") do
      expect(Anyway.env.fetch("RSPECO")).to eq({
        "one" => "ein",
        "two" => "duo"
      })
    end

    expect(Anyway.env.fetch("RSPECO")).to eq({
      "one" => 1,
      "two" => "duo"
    })
  end
end
