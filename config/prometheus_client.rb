# frozen_string_literal: true

unless Rails.env.test?
  require 'prometheus_exporter/client'
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(host: ENV.fetch('PROMETHEUS_EXPORTER_HOST'),
                                                                      port: ENV.fetch('PROMETHEUS_EXPORTER_PORT'))
end
