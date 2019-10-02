# frozen_string_literal: true

unless Rails.env.test?
  require_relative '../prometheus_client'

  require 'prometheus_exporter/middleware'

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
end
