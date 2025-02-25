# frozen_string_literal: true

require "rails/commands/credentials/credentials_command"

module Rails
  module Command
    class LocalCredentialsCommand < CredentialsCommand
      desc "edit", "Open the decrypted local credentials in `$VISUAL` or `$EDITOR` for editing"
      def edit
        load_environment_config!
        load_generators

        @content_path = "config/credentials/local.yml.enc"
        @key_path = "config/credentials/local.key"

        ensure_encryption_key_has_been_added
        ensure_credentials_have_been_added
        ensure_diffing_driver_is_configured

        change_credentials_in_system_editor
      end

      private

      def load_environment_config!
        ENV["ANYWAY_SUPPRESS_VALIDATIONS"] = "true"
        super
      end
    end
  end
end
