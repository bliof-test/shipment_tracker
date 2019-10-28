# frozen_string_literal: true

require 'prometheus_exporter/client'

PrometheusExporter::Client.default = PrometheusExporter::Client.new(
  host: ENV.fetch('PROMETHEUS_EXPORTER_HOST'),
  port: ENV.fetch('PROMETHEUS_EXPORTER_PORT'),
  custom_labels: { hostname: `hostname`.strip },
)
