# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

module Anyway
  using RubyNext

  module Loaders
    class Doppler < Base
      class RequestError < StandardError; end

      class << self
        attr_accessor :download_url
        attr_writer :token

        def token
          @token || ENV["DOPPLER_TOKEN"]
        end
      end

      self.download_url = "https://api.doppler.com/v3/configs/config/secrets/download"

      def call(env_prefix:, **_options)
        env_payload = parse_doppler_response(url: Doppler.download_url, token: Doppler.token)

        env = ::Anyway::Env.new(type_cast: ::Anyway::NoCast, env_container: env_payload)

        env.fetch_with_trace(env_prefix).then do |(conf, trace)|
          Tracing.current_trace&.merge!(trace)
          conf
        end
      end

      private

      def parse_doppler_response(url:, token:)
        response = fetch_doppler_config(url, token)

        unless response.is_a?(Net::HTTPSuccess)
          raise RequestError, "#{response.code} #{response.message}"
        end

        JSON.parse(response.read_body)
      end

      def fetch_doppler_config(url, token)
        uri = URI.parse(url)
        raise "Doppler token is required to load configuration from Doppler" if token.nil?

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == "https"

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["Authorization"] = "Bearer #{token}"

        http.request(request)
      end
    end
  end
end
