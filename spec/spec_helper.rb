# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

begin
  require "pry-byebug"
rescue LoadError
end

NORAILS = ENV["NORAILS"] == "1"

if NORAILS
  ENV["RACK_ENV"] = "test"

  require "anyway_config"

  Anyway::Settings.use_local_files = false
else
  ENV["RAILS_ENV"] = "test"

  require File.expand_path("dummy/config/environment", __dir__)
  Rails.application.eager_load!
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_excluding(rails: true) if NORAILS
  config.filter_run_excluding(norails: true) unless NORAILS

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed
end
