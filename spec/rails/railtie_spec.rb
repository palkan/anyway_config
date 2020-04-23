# frozen_string_literal: true

require "spec_helper"

describe "rails integrations", :rails do
  unless ENV["DO_NOT_INITIALIZE_RAILS"] == "1" || ENV["USE_APP_CONFIGS"] == "1"
    describe "eager_load" do
      specify "config classes must be loaded" do
        expect(Object.const_defined?(:EagerConfig)).to eq true
      end
    end
  end
end
