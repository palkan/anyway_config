# frozen_string_literal: true

require "net/http"

using RubyNext

module Anyway
  module Loaders
    class Doppler < Base
      using Anyway::Ext::Hash

      DOPPLER_API_URL = "https://api.doppler.com/v3/configs/config/secrets/download?name_transformer=lower-snake"

      attr_reader :raw_data

      def initialize(local:)
        super(local:)
        doppler_token = ENV["DOPPLER_TOKEN"]
        raise "Please specify `DOPPLER_TOKEN` env variable" if doppler_token.nil?

        uri = URI(DOPPLER_API_URL)
        headers = {
          Accept: "application/json",
          Authorization: "Bearer #{doppler_token}"
        }

        res = Net::HTTP.get_response(uri, headers)
        body_parsed = JSON.parse(res.body)
        raise "Doppler API error: #{body_parsed["messages"]}" unless res.is_a?(Net::HTTPSuccess)
        @raw_data = body_parsed
      end

      def call(env_prefix:, **options)
        match_prefix = "#{env_prefix.downcase}_"
        trace!(:doppler) do
          raw_data.each_pair.with_object({}) do |(key, val), data|
            next unless key.downcase.start_with?(match_prefix)
            path = key.sub(/^#{match_prefix}/, "").downcase
            paths = path.split("__")
            data.bury(val, *paths)
          end
        end
      end
    end
  end
end
