# frozen_string_literal: true

# Make sure you have generated `sig/types/config.rbs` via:
#   bundle exec rake rbs:generate
#

require_relative "config"

ENV["RBS_TEST_VERSION"] = "1.0"

default = RBS::Config.new

custom = RBS::Config.new(
  version: "2.1",
  revision: "x",
  checker: "steep",
  strictness: :none,
  logger: nil,
  log_params: {},
  debug: true
)

custom.debug?

# #reload
custom.reload
# #reload with overrides
default.reload(log_params: {log_level: "debug"})

default.to_source_trace
