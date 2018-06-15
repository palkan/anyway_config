# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Env do
  let(:env) { Anyway.env }

  it "loads simple key/values by module", :aggregate_failures do
    ENV['TESTO_KEY'] = 'a'
    ENV['MY_TEST_KEY'] = 'b'
    expect(env.fetch('testo')['key']).to eq 'a'
    expect(env.fetch('my_test')['key']).to eq 'b'
  end

  it "loads hash values", :aggregate_failures do
    ENV['TESTO_DATA__ID'] = '1'
    ENV['TESTO_DATA__META__NAME'] = 'meta'
    ENV['TESTO_DATA__META__VAL'] = 'true'
    testo_config = env.fetch('testo')
    expect(testo_config['data']['id']).to eq 1
    expect(testo_config['data']['meta']['name']).to eq 'meta'
    expect(testo_config['data']['meta']['val']).to be_truthy
  end

  it "loads array values", :aggregate_failures do
    ENV['TESTO_DATA__IDS'] = '1,2, 3'
    ENV['TESTO_DATA__META__NAMES'] = 'meta, kotleta'
    ENV['TESTO_DATA__META__SIZE'] = '2'
    ENV['TESTO_DATA__TEXT'] = '"C\'mon, everybody"'
    testo_config = env.fetch('testo')
    expect(testo_config['data']['ids']).to include(1, 2, 3)
    expect(testo_config['data']['meta']['names']).to include('meta', 'kotleta')
    expect(testo_config['data']['meta']['size']).to eq 2
    expect(testo_config['data']['text']).to eq "C'mon, everybody"
  end

  it "returns deep duped hash" do
    ENV['TESTO_CONF'] = 'path/to/conf.yml'
    ENV['TESTO_DATA__ID'] = '1'
    ENV['TESTO_DATA__META__NAME'] = 'meta'
    ENV['TESTO_DATA__META__VAL'] = 'true'
    testo_config = env.fetch('testo')
    testo_config.delete('conf')
    testo_config['data']['meta'].delete('name')

    new_config = env.fetch('testo')
    expect(new_config['data']['meta']['name']).to eq 'meta'
    expect(new_config['conf']).to eq 'path/to/conf.yml'
  end
end
