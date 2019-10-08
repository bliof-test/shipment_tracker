# frozen_string_literal: true

unless Rails.env.test?
  require 'prometheus_exporter/middleware'

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  %w[fetch clone].each do |operation|
    notification = "#{operation}.git_repository_loader"
    ActiveSupport::Notifications.subscribe(notification) do |_, start, finish, _, payload|
      gauge = PrometheusExporter::Client.default.register(
        :gauge,
        "git_#{operation}_duration_seconds",
        "The duration of a git #{operation} operation in seconds",
      )

      gauge.observe(
        finish - start,
        repository: payload[:repository],
      )
    end
  end
end
