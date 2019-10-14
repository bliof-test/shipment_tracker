# frozen_string_literal: true

require 'prometheus_exporter'
require 'prometheus_exporter/instrumentation'
require_relative 'prometheus_client'

port_http = ENV.fetch('PORT_HTTP')
pid_file = '/tmp/unicorn.pid'

PrometheusExporter::Instrumentation::Unicorn.start(
  pid_file: pid_file,
  listener_address: "0.0.0.0:#{port_http}",
)

worker_processes Integer(ENV['WEB_CONCURRENCY'] || 1)
preload_app true
listen port_http
timeout ENV.fetch('UNICORN_TIMEOUT', 60).to_i
pid pid_file

unless ENV['PROTECT_STDOUT'] == 'true'
  root = File.expand_path('..', __dir__)
  paths = {
    stderr: File.join(root, 'log/production.log'),
    stdout: File.join(root, 'log/production.log'),
  }

  stderr_path paths.fetch(:stderr)
  stdout_path paths.fetch(:stdout)
end

before_fork do |_server, _worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    $healthcheck = 'term'
  end

  require 'prometheus_exporter/instrumentation'
  PrometheusExporter::Instrumentation::Process.start(type: 'web')

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
