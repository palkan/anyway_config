# frozen_string_literal: true

require "spec_helper"

describe Anyway::EJSONParser do
  subject { described_class.new.call(file_path) }

  let(:file_path) { "#{Anyway::Settings.app_root}/ejson/correct.ejson" }
  let(:ejson_keydir) { "#{Anyway::Settings.app_root}/ejson/keys" }

  before do
    ENV["EJSON_KEYDIR"] = ejson_keydir
  end

  after do
    ENV["EJSON_KEYDIR"] = nil
  end

  it "decrypts and parses EJSON file into Hash" do
    expect(subject).to eq(
      {
        "_public_key" => "57f49135636ef90e35a6ea7fed5772a101002c501b0405297d2c2b4fd8db9739",
        "_database_username" => "1234username",
        "database_password" => "1234password"
      }
    )
  end

  context "when `ejson` executable is not in the PATH" do
    before do
      stub_const("ENV", ENV.to_hash.merge("PATH" => ""))
    end

    it "returns nil" do
      expect(subject).to eq(nil)
    end
  end

  context "when file does not exist" do
    let(:file_path) { "#{Anyway::Settings.app_root}/ejson/no.ejson" }

    it "returns nil" do
      expect(subject).to eq(nil)
    end
  end

  context "when file decryption fails" do
    let(:ejson_keydir) { "#{Anyway::Settings.app_root}/ejson" }

    it "returns nil" do
      expect(subject).to eq(nil)
    end
  end
end