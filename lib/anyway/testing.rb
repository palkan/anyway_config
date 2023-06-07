# frozen_string_literal: true

require "anyway/testing/helpers"

if defined?(RSpec::Core) && RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(
      Anyway::Testing::Helpers,
      type: :config,
      file_path: %r{spec/configs}
    )
  end
end
