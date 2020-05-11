# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

task(:spec).clear
desc "Run specs with Rails app"
RSpec::Core::RakeTask.new("spec") do |task|
  ENV["NORAILS"] = "0"
  ENV["USE_APP_CONFIGS"] = "0"
  ENV["DO_NOT_INITIALIZE_RAILS"] = "0"
  task.verbose = false
end

desc "Run acceptance specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  ENV["NORAILS"] = "1"
  ENV["USE_APP_CONFIGS"] = "0"
  ENV["DO_NOT_INITIALIZE_RAILS"] = "0"
  task.verbose = false
end

desc "Run Rails secrets tests for uninitialized app"
RSpec::Core::RakeTask.new("spec:secrets") do |task|
  ENV["DO_NOT_INITIALIZE_RAILS"] = "1"
  ENV["USE_APP_CONFIGS"] = "0"
  ENV["NORAILS"] = "0"
  task.rspec_opts = "--order defined --tag secrets"
  task.verbose = false
end

desc "Run Rails autoload tests for app/configs"
RSpec::Core::RakeTask.new("spec:autoload") do |task|
  ENV["USE_APP_CONFIGS"] = "1"
  ENV["NORAILS"] = "0"
  ENV["DO_NOT_INITIALIZE_RAILS"] = "0"
  task.verbose = false
end

desc "Run Ruby Next nextify"
task :nextify do
  sh "bundle exec ruby-next nextify -V"
end

desc "Run the all specs"
task default: %w[spec:norails spec spec:secrets spec:autoload]
