# frozen_string_literal: true

pid_file = './tmp/unicorn.pid'
port = ENV.fetch('PORT_HTTP')

require_relative '../lib/prometheus_client'

worker_processes ENV.fetch('WEB_CONCURRENCY', 4).to_i

pid pid_file
listen port

preload_app true
timeout ENV.fetch('UNICORN_TIMEOUT', 60).to_i

PrometheusClient.instrument_unicorn(
  pid_file: pid_file,
  listener_address: "0.0.0.0:#{port}",
  frequency: 10,
)

before_fork do |_server, _worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    $healthcheck = 'term'
  end

  PrometheusClient.instrument_process(type: 'web')

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
