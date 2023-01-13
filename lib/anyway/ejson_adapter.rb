# frozen_string_literal: true

module Anyway
  class EJSONAdapter
    def parse(file_path)
      return unless which('ejson')
      return unless File.exists?(file_path)

      cmd_result =
        Open3.popen3("ejson decrypt #{file_path}") do |stdin, stdout, stderr, thread|
          stdout.read.chomp
        end

      JSON.parse(cmd_result)
    rescue JSON::ParserError
      nil
    end

    private

    # Cross-platform solution
    # taken from https://stackoverflow.com/a/5471032
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end
  end
end
