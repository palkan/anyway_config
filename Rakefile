require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec2) do |t|
  t.pattern = "./spec/**/*_norails.rb"
end

task :default => [:spec2, :spec]