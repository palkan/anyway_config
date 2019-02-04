# frozen_string_literal: true

module Anyway # :nodoc:
  require "anyway/version"

  # Refinements
  require "anyway/ext/jruby" if defined? JRUBY_VERSION
  require "anyway/ext/deep_dup"
  require "anyway/ext/deep_freeze"
  require "anyway/ext/hash"
  require "anyway/ext/string_serialize"

  require "anyway/config"
  require "anyway/rails/config" if defined?(::Rails::VERSION)
  require "anyway/env"

  def self.env
    @env ||= ::Anyway::Env.new
  end
end
