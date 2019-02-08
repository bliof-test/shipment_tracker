# frozen_string_literal: true

worker_processes Integer(ENV['WEB_CONCURRENCY'] || 1)
preload_app true
listen ENV.fetch('PORT_HTTP')
timeout ENV.fetch('UNICORN_TIMEOUT', 60).to_i

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

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
