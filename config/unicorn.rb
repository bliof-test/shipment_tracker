worker_processes Integer(ENV['WEB_CONCURRENCY'] || 1)
timeout 27
preload_app true

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
  Signal.trap 'TERM' do
    Rails.logger.warn 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    Rails.logger.warn 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
