module Anyway # :nodoc:
  require "anyway/version"
  require "anyway/config"
  require "anyway/rails/config" if defined?(Rails)
  require "anyway/env"

  def self.env
    @env ||= ::Anyway::Env.new
  end
end
