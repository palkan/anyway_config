# frozen_string_literal: true

module Anyway
  module Utils
    # Cross-platform solution
    # taken from https://stackoverflow.com/a/5471032
    def self.which(cmd)
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end
  end
end
