# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anyway::Utils do
  describe '.which' do
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
  end
end
