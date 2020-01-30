# frozen_string_literal: true

unless Rails.env.test?
  require 'prometheus_exporter/middleware'

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  git_fetch_duration_gauge = PrometheusExporter::Client.default.register(
    :gauge,
    "git_fetch_duration_seconds",
    "The duration of a git fetch operation in seconds",
  )

  ActiveSupport::Notifications.subscribe("fetch.git_repository_loader") do |_, start, finish, _, payload|
    git_fetch_duration_gauge.observe(finish - start, repository: payload[:repository])
  end

  git_clone_duration_gague = PrometheusExporter::Client.default.register(
    :gauge,
    "git_clone_duration_seconds",
    "The duration of a git clone operation in seconds",
  )

  ActiveSupport::Notifications.subscribe("clone.git_repository_loader") do |_, start, finish, _, payload|
    git_clone_duration_gague.observe(finish - start, repository: payload[:repository])
  end
end
