# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require "rubocop/rake_task"

RuboCop::RakeTask.new

task(:spec).clear
desc "Run specs with Rails app"
RSpec::Core::RakeTask.new("spec") do |task|
  task.exclude_pattern = "spec/**/*_norails.rb"
  task.verbose = false
end

desc "Run acceptance specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  task.pattern = "spec/**/*_norails.rb"
  task.verbose = false
end

desc "Run the all specs and linters"
task default: %w[spec:norails spec rubocop]
