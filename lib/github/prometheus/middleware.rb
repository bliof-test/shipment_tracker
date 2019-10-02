require 'prometheus_exporter/client'
require 'faraday'

module Github
  module Prometheus
    class Middleware < Faraday::Response::Middleware
      def on_complete(env)
        ::PrometheusExporter::Client.default.send_json(
          github_rate_limit_requests_remaining: env.response_headers['x-ratelimit-remaining'].to_i
        )
      end

      ::Faraday::Response.register_middleware github_prometheus_collector: self
    end
  end
end