# frozen_string_literal: true

require "anyway_config"

module RBS; end

class RBS::Config < Anyway::Config
  config_name :rbs

  env_prefix "RBS_TEST"

  # basic
  attr_config :version, :revision

  # with defaults
  attr_config checker: "steep", strictness: :strict

  # mixed
  attr_config :logger, log_params: {level: 2, device: nil}, tags: ["test"], debug: false

  # type coercion
  coerce_types version: :string, log_params: {level: :integer}, tags: {type: :string, array: true}
  coerce_types tags: {type: nil, array: true}

  disable_auto_cast!

  # option parser integration
  describe_options(
    version: "signature version",
    checker: {
      desc: "Type checker",
      type: String
    }
  )

  ignore_options :log_params
  flag_options :debug

  extend_options do |parser, config|
    parser.banner = "Testing type generation"
  end

  # validations and callbacks
  required :version, :checker

  on_load :normalize_checker

  on_load do
    # @type self : RBS::Config
    raise_validation_error("checker is missing") if checker.nil?
  end

  # super is available
  def revision
    super || (self.revision = "unknown")
  end

  private

  def normalize_checker
    self.checker = "" unless /steep/i.match?(checker)
  end
end
