# frozen_string_literal: true

describe Anyway::Utils do
  describe ".which" do
    subject { described_class.which("ejson") }

    it { expect(subject).to be_a(String) }

    context "when `ejson` executable is not in the PATH" do
      before do
        stub_const("ENV", ENV.to_hash.merge("PATH" => ""))
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when PATH is not set" do
      before do
        stub_const("ENV", ENV.to_hash.tap { |env| env.delete("PATH") })
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
