# frozen_string_literal: true

require_relative './mock_context'

using(Module.new do
  refine Class.singleton_class do
    def instance_class
      eval inspect.sub(%r{^#<Class:}, '').sub(/>$/, '')
    end
  end
end)

RSpecMockContext.collector.rewrite(:perform_async) do |mod, method_name|
  [mod.instance_class, :perform]
end

RSpecMockContext.calls.rewrite(:perform) do |mod, method_name|
  [mod.singleton_class, :perform_async]
end

RSpec.configure do |config|
  config.before(:suite) do
    # p RSpecMockContext.collector.mocks
    RSpecMockContext.calls.start!(RSpecMockContext.collector.mocked_methods)
  end

  # Custom hook to run post-checks after all groups
  # but before collecting examples data.
  config.after(:suite) do
    RSpecMockContext.calls.stop
    contract_check_passed = RSpecMockContext.collector.verify!(RSpecMockContext.calls.store)

    TypedVerifyingProxy::RBSHelper.generate!(
      RSpecMockContext.calls.store
    )

    type_check_passed = TypedVerifyingProxy::RBSHelper.postcheck!
    exit(RSpec.configuration.failure_exit_code) unless type_check_passed && contract_check_passed
  end
end
