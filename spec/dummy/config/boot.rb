# frozen_string_literal: true

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../../Gemfile", __FILE__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
lib_path = File.expand_path("../../../../lib", __FILE__)
# Do not move lib in front of the Ruby Next load paths if the gem has been already loaded
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
