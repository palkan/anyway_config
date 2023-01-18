# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

module Anyway
  using RubyNext

  module Loaders
    class Doppler < Base
      DOPPLER_REQUEST_ERROR = Class.new(StandardError)
      DOPPLER_JSON_FORMAT_URL = "https://api.doppler.com/v3/configs/config/secrets/download"

      def call(env_prefix:, **)
        env_payload = parse_doppler_response

        env = ::Anyway::Env.new(type_cast: ::Anyway::NoCast, env_container: env_payload)

        env.fetch_with_trace(env_prefix).then do |(conf, trace)|
          Tracing.current_trace&.merge!(trace)
          conf
        end
      end

      private

      def parse_doppler_response
        response = fetch_doppler_config

        unless response.is_a?(Net::HTTPSuccess)
          raise DOPPLER_REQUEST_ERROR, "#{response.code} #{response.message}"
        end

        JSON.parse(response.read_body)
      end

      def fetch_doppler_config
        uri = URI.parse(DOPPLER_JSON_FORMAT_URL)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["Authorization"] = "Bearer #{ENV.fetch("DOPPLER_TOKEN")}"

        http.request(request)
      end
    end
  end
end
