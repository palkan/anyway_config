require 'spec_helper'

describe Anyway::Env do
  let(:env) { Anyway.env.reload }

  it "should load simple key/values by module" do
    ENV['TESTO_KEY'] = 'a'
    ENV['MYTEST_KEY'] = 'b'
    expect(env.testo[:key]).to eq 'a'
    expect(env.my_test['key']).to eq 'b'
  end

  it "should load hash values" do
    ENV['TESTO_DATA__ID'] = '1'
    ENV['TESTO_DATA__META__NAME'] = 'meta'
    ENV['TESTO_DATA__META__VAL'] = '2'
    expect(env.testo[:data][:id]).to eq '1'
    expect(env.testo[:data][:meta][:name]).to eq 'meta'
    expect(env.testo[:data][:meta][:val]).to eq '2'
  end
end