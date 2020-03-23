# frozen_string_literal: true

require "rails/generators"

module Anyway
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_application_config
        template "application_config.rb", "app/configs/application_config.rb"
      end

      def add_local_files_to_gitignore
        if File.exist?(File.join(destination_root, ".gitignore"))
          append_to_file ".gitignore", "\n/config/*.local.yml\n/config/credentials/local.*\n"
        end
      end
    end
  end
end
