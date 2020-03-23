# frozen_string_literal: true

require "rails/generators"

module Anyway
  module Generators
    class ConfigGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :yml, type: :boolean
      argument :parameters, type: :array, default: [], banner: "param1 param2"

      check_class_collision suffix: "Config"

      def run_install_if_needed
        return if ::Rails.root.join("app/configs/application_config.rb").exist?
        generate "anyway:install"
      end

      def create_config
        template "config.rb", File.join("app/configs", class_path, "#{file_name}_config.rb")
      end

      def create_yml
        create_yml = options.fetch(:yml) { ask("Would you like to generate a #{file_name}.yml file? (Y/n)").match?(/^y\s*/i) }
        return unless create_yml
        template "config.yml", File.join("config", "#{file_name}.yml")
      end
    end
  end
end
