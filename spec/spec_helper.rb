# frozen_string_literal: true

begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

ENV["RUBY_NEXT_WARN"] = "false"
ENV["RUBY_NEXT_EDGE"] = "1"
ENV["RUBY_NEXT_PROPOSED"] = "1"
require "ruby-next/language/runtime" unless ENV["CI"]

require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)

NORAILS = ENV["NORAILS"] == "1"

begin
  if NORAILS
    ENV["RACK_ENV"] = "test"

    require "anyway_config"

    Anyway::Settings.use_local_files = false
  else
    ENV["RAILS_ENV"] = "test"

    # Load anyway_config before Rails to test that we can detect Rails app before it's loaded
    require "anyway_config"

    require "ammeter"

    require File.expand_path("dummy/config/environment", __dir__)
  end
rescue => err
  $stdout.puts "Failed to load test env: #{err}\n#{err.backtrace.take(5).join("\n")}"
  exit(1)
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_excluding(rails: true) if NORAILS
  config.filter_run_excluding(norails: true) unless NORAILS
  # Igonore specs manually checking for argument types when running RBS runtime tester
  config.filter_run_excluding(rbs: false) if defined?(::RBS::Test)

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed
end
