# frozen_string_literal: true

# Run with the following command:
#
#  ruby -r ./rubyconf_config.rb -e 'pp RubyConfConfig.new'
#

$LOAD_PATH.unshift("../lib")

require "anyway_config"
require "date"

class RubyConfConfig < Anyway::Config
  attr_config :city, :date
  coerce_types date: :date
end
