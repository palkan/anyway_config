# frozen_string_literal: true

require 'optparse'
require 'anyway/ext/string'

module Anyway # :nodoc:
  using Anyway::Ext::String

  # Initializes the OptionParser instance using the given configuration
  class OptionParserBuilder
    class << self
      def call(options)
        OptionParser.new do |opts|
          options.each do |key, description|
            opts.on(*option_parser_on_args(key, description)) do |arg|
              yield [key, arg.serialize]
            end
          end
        end
      end

      private

      def option_parser_on_args(key, description)
        on_args = ["--#{key.to_s.tr('_', '-')} VALUE"]
        on_args << description unless description.nil?
        on_args
      end
    end
  end
end
