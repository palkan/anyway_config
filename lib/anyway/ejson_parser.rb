# frozen_string_literal: true

require 'open3'

module Anyway
  class EJSONParser
    def call(file_path)
      return unless File.exist?(file_path)

      cmd_result =
        Open3.popen3("ejson decrypt #{file_path}") do |stdin, stdout, stderr, thread|
          stdout.read.chomp
        end

      JSON.parse(cmd_result)
    rescue JSON::ParserError
      nil
    end
  end
end
