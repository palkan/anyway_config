require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/core_ext/object'

require "anyway/version"
module Anyway
  require "anyway/config"
  require "anyway/rails/config" if defined?(Rails)
  require "anyway/env"

  def self.env
    @env ||= ::Anyway::Env.new
  end
end
