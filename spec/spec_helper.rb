# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end

ENV["RUBY_NEXT_WARN"] = "false"
ENV["RUBY_NEXT_EDGE"] = "1"
ENV["RUBY_NEXT_PROPOSED"] = "1"
require "ruby-next/language/runtime" unless ENV["CI"]

NORAILS = ENV["NORAILS"] == "1"

if ENV["VERIFY_RESERVED"] == "1"
  require "set"

  called_methods = Set.new
  lib_path = File.realpath(File.join(File.dirname(__FILE__), "..", "lib"))

  TracePoint.new(:call) do |ev|
    # already tracked
    next if called_methods.include?(ev.method_id)
    # the event could be triggered before we load Anyway::Config
    next unless defined?(Anyway::Config)
    # filter out methods called not on Config instances
    next unless Anyway::Config === ev.self
    # select only methods defined by the library, not user
    next unless ev.defined_class == Anyway::Config || Anyway::Config.included_modules.include?(ev.defined_class)
    # make sure the method is called from the library code, not tests
    next unless ev.binding.eval("caller").any? { |path| path.start_with?(lib_path) }

    called_methods << ev.method_id
  end.enable

  RSpec.configure do |config|
    config.after(:suite) do
      called_methods = called_methods.to_a.select { |mid| mid =~ Anyway::Config::PARAM_NAME }

      if (called_methods - Anyway::Config::RESERVED_NAMES).empty?
        next puts "\nAnyway::Config::RESERVED is OK"
      end

      raise "Anyway::Config::RESERVED is invalid.\n" \
        "Expected to contain: #{called_methods.sort}.\n" \
        "Contains: #{Anyway::Config::RESERVED_NAMES.sort}.\n" \
        "Missing elements: #{(called_methods - Anyway::Config::RESERVED_NAMES).sort}"
    end
  end
end

begin
  if NORAILS
    ENV["RACK_ENV"] = "test"

    require "anyway_config"

    Anyway::Settings.use_local_files = false
  else
    ENV["RAILS_ENV"] = "test"

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
