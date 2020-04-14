# frozen_string_literal: true

# Run `ruby-next nextify` when installing from source (i.e., if .rbnext folder is missing)

# First, create a dummy Makefile to comply with Ruby extensions
require "mkmf"
create_makefile ""

return if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")

COMMAND = "ruby-next nextify ./lib --transpile-mode=rewrite"

# Check for the .rbnext folder presence
Dir.chdir(File.join(__dir__, "..")) do
  next if File.directory?("lib/.rbnext")

  rbnext_installed = `gem list -i ruby-next -v '~> 0.5'`

  if /true/.match?(rbnext_installed)
    $stdout.puts "Transpiling source code for anyway_config"
    return if system COMMAND
  end

  $stdout.puts "Failed to install anyway_config from source: ensure you have ruby-next >= 0.5.0 installed as a default Ruby Next version.\n" \
    "You can install it by running: gem install ruby-next -v '~> 0.5' --default"
  exit(1)
end
