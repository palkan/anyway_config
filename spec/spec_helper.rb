$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

begin
  require "pry-byebug"
rescue LoadError
end

ENV["RAILS_ENV"] = 'test'

require File.expand_path("../dummy/config/environment", __FILE__)
require 'anyway'

Rails.application.eager_load!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
end
