# frozen_string_literal: true

require 'faraday'
require 'logger'
require 'prometheus_exporter'
require 'prometheus_exporter/client'
require 'prometheus_exporter/instrumentation'
require 'prometheus_exporter/middleware'

module PrometheusClient
  module_function

  def logger
    @logger ||= Logger.new($stdout)
  end

  def instrument_unicorn(pid_file:, listener_address:, frequency:)
    return unless instrument?

    logger.info(
      "Instrumenting unicorn pid_file: #{pid_file} listener_address: #{listener_address} frequency: #{frequency}",
    )

    PrometheusExporter::Instrumentation::Unicorn.start(
      pid_file: pid_file,
      listener_address: listener_address,
      frequency: frequency,
    )
  end

  def instrument_process(type:)
    return unless instrument?

    logger.info("Instrumenting process type: #{type}")

    PrometheusExporter::Instrumentation::Process.start(type: type)
  end

  def instrument_octokit
    return unless instrument?

    Octokit.middleware.use GithubMiddleware
  end

  def instrument_delayed_job
    return unless instrument?

    logger.info('Instrumenting delayed_job')

    PrometheusExporter::Instrumentation::DelayedJob.register_plugin
  end

  def instrument_rack
    return unless instrument?

    logger.info('Instrumenting rack')

    # This reports stats per request like HTTP status and timings
    Rails.application.middleware.unshift PrometheusExporter::Middleware
  end

  def register(type, name, help, opts = nil)
    logger.info("Registering metric #{name} type: #{type}, help: #{help}, opts: #{opts}")

    PrometheusExporter::Client.default.register(type, name, help, opts)
  end

  def instrument?
    !default_client.nil?
  end

  def default_client
    return @default_client if @default_client

    @default_client = ENV['PROMETHEUS_EXPORTER_HOST'] ? _external_client : _local_client

    PrometheusExporter::Client.default = @default_client
  end

  def _external_client
    PrometheusExporter::Client.new(
      host: ENV.fetch('PROMETHEUS_EXPORTER_HOST'),
      port: ENV.fetch('PROMETHEUS_EXPORTER_PORT'),
      custom_labels: { hostname: `hostname`.strip },
    )
  end

  def _local_client
    require 'prometheus_exporter/server'

    port = (ENV['PROMETHEUS_LOCAL_PORT'] || 3001).to_i

    logger.info "Exposing prometheus metrics on http://localhost:#{port}/metrics"

    server = PrometheusExporter::Server::WebServer.new(port: port)
    server.start

    PrometheusExporter::LocalClient.new(collector: server.collector)
  end

  class GithubMiddleware < Faraday::Response::Middleware
    REQUESTS_REMAINING_GAUGE = PrometheusClient.register(
      :gauge,
      'github_rate_limit_requests_remaining',
      'The number of GitHub API requests remaining until rate limited',
    )

    def on_complete(env)
      REQUESTS_REMAINING_GAUGE.observe(env.response_headers['x-ratelimit-remaining'].to_i)
    end
  end
end
