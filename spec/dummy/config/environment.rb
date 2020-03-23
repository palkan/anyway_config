# frozen_string_literal: true

# Load the Rails application
require_relative "./application"

# Initialize the Rails application.
Dummy::Application.initialize! unless ENV["DO_NOT_INITIALIZE_RAILS"] == "1"
