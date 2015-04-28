module Anyway
  class TestConfig < Anyway::Config # :nodoc:
    attr_config :test, api: { key: '' }
  end
end
