# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # p RSpecMockContext.collector.mocks
    RSpecMockContext.calls.start!(RSpecMockContext.collector.mocked_methods)
  end

  # Custom hook to run post-checks after all groups
  # but before collecting examples data.
  config.after(:suite) do
    RSpecMockContext.calls.stop

    TypedVerifyingProxy::RBSHelper.generate!(
      RSpecMockContext.calls.store
    )

    passed = TypedVerifyingProxy::RBSHelper.postcheck!
    exit(RSpec.configuration.failure_exit_code) unless passed
  end
end
