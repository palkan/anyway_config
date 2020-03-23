# frozen_string_literal: true

class ApplicationConfig < Anyway::Config
  class << self
    def instance
      @instance ||= new
    end
  end
end
