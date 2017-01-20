require 'spec_helper'

describe Anyway::Env do
  let(:env) { Anyway.env.reload }

  it "should load simple key/values by module", :aggregate_failures do
    ENV['TESTO_KEY'] = 'a'
    ENV['MYTEST_KEY'] = 'b'
    expect(env.testo['key']).to eq 'a'
    expect(env.my_test['key']).to eq 'b'
  end

  it "should load hash values", :aggregate_failures do
    ENV['TESTO_DATA__ID'] = '1'
    ENV['TESTO_DATA__META__NAME'] = 'meta'
    ENV['TESTO_DATA__META__VAL'] = 'true'
    expect(env.testo['data']['id']).to eq 1
    expect(env.testo['data']['meta']['name']).to eq 'meta'
    expect(env.testo['data']['meta']['val']).to be_truthy
  end

  it "should load array values", :aggregate_failures do
    ENV['TESTO_DATA__IDS'] = '1,2, 3'
    ENV['TESTO_DATA__META__NAMES'] = 'meta, kotleta'
    ENV['TESTO_DATA__META__SIZE'] = '2'
    ENV['TESTO_DATA__TEXT'] = '"C\'mon, everybody"'
    expect(env.testo['data']['ids']).to include(1, 2, 3)
    expect(env.testo['data']['meta']['names']).to include('meta', 'kotleta')
    expect(env.testo['data']['meta']['size']).to eq 2
    expect(env.testo['data']['text']).to eq "C'mon, everybody"
  end
end
