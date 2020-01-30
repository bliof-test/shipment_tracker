# frozen_string_literal: true

unless Rails.env.test?
  PrometheusClient.instrument_rack

  git_fetch_duration_gauge = PrometheusClient.register(
    :gauge,
    'git_fetch_duration_seconds',
    'The duration of a git fetch operation in seconds',
  )

  ActiveSupport::Notifications.subscribe('fetch.git_repository_loader') do |_, start, finish, _, payload|
    git_fetch_duration_gauge.observe(finish - start, repository: payload[:repository])
  end

  git_clone_duration_gauge = PrometheusClient.register(
    :gauge,
    'git_clone_duration_seconds',
    'The duration of a git clone operation in seconds',
  )

  ActiveSupport::Notifications.subscribe('clone.git_repository_loader') do |_, start, finish, _, payload|
    git_clone_duration_gauge.observe(finish - start, repository: payload[:repository])
  end
end
