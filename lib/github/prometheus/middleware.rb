# frozen_string_literal: true

require 'prometheus_exporter/client'
require 'faraday'

module Github
  module Prometheus
    class Middleware < Faraday::Response::Middleware
      REQUESTS_REMAINING_GAUGE = PrometheusExporter::Client.default.register(
        :gauge,
        'github_rate_limit_requests_remaining',
        'The number of GitHub API requests remaining until rate limited',
      )

      def on_complete(env)
        REQUESTS_REMAINING_GAUGE.observe(env.response_headers['x-ratelimit-remaining'].to_i)
      end
    end
  end
end
