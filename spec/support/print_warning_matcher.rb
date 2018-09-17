# frozen_string_literal: true

RSpec::Matchers.define :print_warning do |message|
  def supports_block_expectations?
    true
  end

  match do |block|
    stderr = fake_stderr(&block)
    message ? stderr.include?(message) : !stderr.empty?
  end

  description do
    "write #{message && "\"#{message}\"" || 'anything'} to standard error"
  end

  failure_message do
    "expected to #{description}"
  end

  failure_message_when_negated do
    "expected not to #{description}"
  end

  # Fake STDERR and return a string written to it.
  def fake_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
