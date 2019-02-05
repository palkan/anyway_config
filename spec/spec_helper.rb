# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

begin
  require "pry-byebug"
rescue LoadError
end

ENV["RAILS_ENV"] = "test"

require File.expand_path("dummy/config/environment", __dir__)
require "anyway_config"

Rails.application.eager_load!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.after(:each) do
    Anyway.env.clear
    ENV.delete_if { |var| var =~ /^(cool_|any|testo_|myapp_)/i }
  end
end
