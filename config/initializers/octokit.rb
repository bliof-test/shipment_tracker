# frozen_string_literal: true

require 'octokit'
require 'github/prometheus/middleware'

Octokit.middleware.use Github::Prometheus::Middleware
