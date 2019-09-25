# frozen_string_literal: true

if Rails.env != 'test'
  require 'prometheus_exporter/client'
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(host: ENV.fetch('PROMETHEUS_EXPORTER_HOST'),
                                                                      port: ENV.fetch('PROMETHEUS_EXPORTER_PORT'))

  require 'prometheus_exporter/middleware'

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  require 'prometheus_exporter/instrumentation'

  # this reports basic process stats like RSS and GC info, type master
  # means it is instrumenting the master process
  PrometheusExporter::Instrumentation::Process.start(type: 'master')
end
