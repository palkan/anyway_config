# frozen_string_literal: true

require "anyway/testing/helpers"

if defined?(RSpec) && defined?(RSpec.configure)
  RSpec.configure do |config|
    config.include(
      Anyway::Testing::Helpers,
      type: :config,
      file_path: %r{spec/configs}
    )
  end
end
