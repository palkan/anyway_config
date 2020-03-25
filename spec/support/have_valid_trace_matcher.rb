# frozen_string_literal: true

using Anyway::Ext::Hash

RSpec::Matchers.define :have_valid_trace do
  match do |conf|
    @values = conf.send(:values).stringify_keys!
    @trace = extract_value(conf.send(:__trace__))
    # Trace collects keys not present in the attr_config
    @trace.keep_if { |k, v| @values.key?(k) }
    @trace == @values
  end

  failure_message do
    "config trace is invalid:\n" \
    " - trace: #{@trace}\n" \
    " - config: #{@values}"
  end

  def extract_value(val)
    if val.trace?
      val.value.transform_values { |v| extract_value(v) }
    else
      val.value
    end
  end
end
