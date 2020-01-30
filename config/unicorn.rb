# frozen_string_literal: true

pid_file = './tmp/unicorn.pid'

require_relative '../lib/prometheus_client'

worker_processes 4

pid pid_file
listen ENV.fetch('PORT_HTTP')

preload_app true
timeout ENV.fetch('UNICORN_TIMEOUT', 60).to_i

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
