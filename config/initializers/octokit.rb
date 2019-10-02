require 'octokit'
require 'github/prometheus/middleware'

Octokit.middleware.use Github::Prometheus::Middleware
