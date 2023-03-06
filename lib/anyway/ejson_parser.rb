# frozen_string_literal: true

require "open3"
require "anyway/ext/hash"

using Anyway::Ext::Hash

module Anyway
  class EJSONParser
    attr_reader :bin_path

    def initialize(bin_path = "ejson")
      @bin_path = bin_path
    end

    def call(file_path)
      return unless File.exist?(file_path)

      raw_content = nil

      stdout, stderr, status = Open3.capture3("#{bin_path} decrypt #{file_path}")

      if status.success?
        raw_content = JSON.parse(stdout.chomp)
      else
        Kernel.warn "Failed to decrypt #{file_path}: #{stderr}"
      end

      return unless raw_content

      raw_content.deep_transform_keys do |key|
        if key[0] == "_"
          key[1..]
        else
          key
        end
      end
    end
  end
end
