require 'prometheus_exporter/server'

module Github
  module Prometheus
    class Collector < PrometheusExporter::Server::CollectorBase
      def initialize
        @requests_remaining_gauge = PrometheusExporter::Metric::Gauge.new(
          'github_rate_limit_requests_remaining',
          'The number of GitHub API requests remaining until rate limited'
        )
        @mutex = Mutex.new
      end

      def process(str)
        obj = JSON.parse(str)
        @mutex.synchronize do
          if requests_remaining = obj['github_rate_limit_requests_remaining']
            @requests_remaining_gauge.observe(requests_remaining)
          end
        end
      end

      def prometheus_metrics_text
        @mutex.synchronize do
          @requests_remaining_gauge.to_prometheus_text
        end
      end
    end
  end
end
