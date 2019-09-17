# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

task(:spec).clear
desc "Run specs with Rails app"
RSpec::Core::RakeTask.new("spec") do |task|
  ENV["NORAILS"] = "0"
  task.verbose = false
end

desc "Run acceptance specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  ENV["NORAILS"] = "1"
  task.verbose = false
end

desc "Run the all specs"
task default: %w[spec:norails spec]
