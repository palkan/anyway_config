# frozen_string_literal: true

require 'open3'
require "anyway/ext/hash"

using Anyway::Ext::Hash

module Anyway
  class EJSONParser
    def call(file_path)
      return unless File.exist?(file_path)

      cmd_result =
        Open3.popen3("ejson decrypt #{file_path}") do |stdin, stdout, stderr, thread|
          stdout.read.chomp
        end

      raw_content = JSON.parse(cmd_result)

      raw_content.deep_transform_keys do |key|
        if key[0] == "_"
          key[1..]
        else
          key
        end
      end
    rescue JSON::ParserError
      nil
    end
  end
end
