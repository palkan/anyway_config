require "anyway/version"

module Anyway
  require "anyway/config"
  require "anyway/env"

  def self.env
    @env ||= ::Anyway::Env.new
  end
end
