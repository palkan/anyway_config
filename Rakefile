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

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  RuboCop::RakeTask.new("rubocop:md") do |task|
    task.options << %w[-c .rubocop-md.yml]
  end
rescue LoadError
  task(:rubocop) {}
  task("rubocop:md") {}
end

namespace :rbs do
  desc "Generate an RBS file from config class"
  task generate: :nextify do
    require "anyway_config"
    require_relative "./sig/types/config"

    File.write("./sig/types/config.rbs", RBS::Config.to_rbs)

    Bundler.with_unbundled_env do
      sh "rbs validate sig/types/config.rbs"
    end
  end

  desc "Typeprof"
  task typeprof: :nextify do
    Bundler.with_unbundled_env do
      sh "typeprof -I./lib -I./lib/.rbnext/1995.next sig/types/*.rb"
    end
  end
end

task :steep do
  # Steep doesn't provide Rake integration yet,
  # but can do that ourselves
  require "steep"
  require "steep/cli"

  Steep::CLI.new(argv: ["check"], stdout: $stdout, stderr: $stderr, stdin: $stdin).run
end

namespace :steep do
  task :stats do
    exec "bundle exec steep stats --log-level=fatal --format=table"
  end
end

namespace :spec do
  desc "Run RSpec with RBS runtime tester enabled"
  task :rbs do
    rspec_args = ARGV.join.split("--", 2).then { _1.size == 2 ? _1.last : nil }
    sh <<~COMMAND
      RACK_ENV=test \
      RBS_TEST_LOGLEVEL=error \
      RBS_TEST_TARGET="Anyway::*" \
      rspec -rrbs/test/setup \
      #{rspec_args}
    COMMAND
  end
end

desc "Run the all specs"
task default: %w[rubocop rubocop:md steep spec:norails spec spec:secrets spec:autoload spec:rbs]
