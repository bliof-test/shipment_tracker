# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

map '/healthcheck' do
  run(proc { [200, {}, ['ok']] })
end

map '/healthcheck-haproxy' do
  run(proc { $healthcheck == 'term' ? [404, {}, ['term']] : [200, {}, ['ok']] })
end

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
